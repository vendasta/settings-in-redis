require 'redis'
require 'active_support/core_ext/hash/indifferent_access'
require 'yaml'

module Settings
  class NoRedisConnection < RuntimeError; end

  def self.redis=(server)
    @redis = server
  end

  def self.redis
    raise NoRedisConnection unless @redis
    @redis
  end
  private_class_method :redis

  def self.defaults=(value)
    @defaults = value
  end

  def self.defaults
    @defaults ||= HashWithIndifferentAccess.new
  end

  # cache must follow the contract of ActiveSupport::Cache. Defaults to no-op.
  def self.cache=(value)
    @cache = value
  end

  def self.cache
    @cache || ActiveSupport::Cache::NullStore.new
  end

  # options passed to cache.fetch() and cache.write().
  # Example: {:expires_in => 5.minutes}
  def self.cache_options=(value)
    @cache_options = value
  end

  def self.cache_options
    @cache_options || {}
  end

  def self.cache_prefix
    @cache_prefix || 'Settings'
  end

  def self.cache_key(var_name)
    "#{cache_prefix}::#{var_name}"
  end

  def self.redis_prefix
    @redis_prefix || 'settings'
  end

  def self.redis_key(var_name)
    "#{redis_prefix}:#{var_name}"
  end
  
  # get or set a variable with the variable as the called method
  def self.method_missing(method, *args)
    if self.respond_to?(method)
      super
    else
      method_name = method.to_s
    
      # set a value for a variable
      if method_name =~ /=$/
        var_name = method_name.gsub('=', '')
        value = args.first
        self[var_name] = value
    
      #retrieve a value
      else
        self[method_name]
      end
    end
  end
  
  # destroy the specified setting
  def self.destroy(var_name)
    var_name = var_name.to_s
    redis.del(redis_key(var_name))
    cache.delete(cache_key(var_name))
  end

  def self.delete_all
    cache.clear
    all_keys = redis.keys("#{redis_prefix}:*")
    redis.del(all_keys) if all_keys.any?
  end

  # retrieve all settings as a hash
  # (optionally starting with a given namespace)
  def self.all(starting_with = nil)
    pattern = ["#{redis_prefix}:", starting_with, '*'].compact.join('')
    all_keys = redis.keys(pattern)
    if all_keys.any?
      values = redis.mget(all_keys).map { |v| deserialize(v) }
      prefix = Regexp.new("^#{redis_prefix}:")
      setting_names = all_keys.map { |k| k.gsub(prefix, '')}
      result = Hash[setting_names.zip(values)]
      result.with_indifferent_access
    else
      HashWithIndifferentAccess.new
    end
  end
  
  # get a setting value by [] notation
  def self.[](var_name)
    cache.fetch(cache_key(var_name), cache_options) do
      value = redis.get(redis_key(var_name))
      if value.present?
        deserialize(value)
      else
        defaults[var_name.to_s]
      end
    end
  end
  
  # set a setting value by [] notation
  def self.[]=(var_name, value)
    redis.set(redis_key(var_name), serialize(value))
    cache.write(cache_key(var_name), value, cache_options)
    value
  end

  # Merge the specified Hash into the an existing setting with a Hash value.
  # @return [Hash]
  def self.merge!(var_name, hash_value)
    raise ArgumentError unless hash_value.is_a?(Hash)
    
    old_value = self[var_name] || {}
    raise TypeError, "Existing value is not a hash, can't merge!" unless old_value.is_a?(Hash)
    
    new_value = old_value.merge(hash_value)
    self[var_name] = new_value if new_value != old_value
    
    new_value
  end

  # decode YAML value
  def self.deserialize(value)
    YAML::load(value)
  end
  private_class_method :deserialize
  
  # YAML encode value
  def self.serialize(value)
    value.to_yaml
  end
  private_class_method :serialize
end
