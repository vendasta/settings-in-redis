# settings-in-redis

This gem provides a `Settings` module that is written to be API-compatible
with the ledermann-rails-settings gem for the management of global settings.

The `Settings` module manages key-value pairs that are stored in Redis. Each
setting is stored as a key with a string value in Redis. You can store any
kind of object which can be serialized as YAML.

## Installation

Include the gem in your Gemfile

    gem 'settings-in-redis'

The connection to Redis must be specified for Settings, for example in an
initializer:

    Settings.redis = Redis.new

Setting values are stored in Redis with a default prefix of "settings:".

## Usage

The syntax is easy. First create some settings to keep track of:

    Settings.admin_password = 'supersecret'
    Settings.date_format    = '%m %d, %Y'
    Settings.cocktails      = ['Martini', 'Screwdriver', 'White Russian']
    Settings.foo            = 123
    Settings.credentials    = { :username => 'tom', :password => 'secret' }

Then read them back:

    Settings.foo
    # => 123

Changing an existing setting is the same as creating a new setting:

    Settings.foo = 'super duper bar'

To change an existing setting which is a Hash, you can merge new values
with existing ones:

    Settings.merge! :credentials, :password => 'topsecret'
    Settings.credentials
    # => { :username => 'tom', :password => 'topsecret' }

Decide that a particular setting is no longer needed?

    Settings.destroy :foo
    Settings.foo
    # => nil

Want a list of all the settings?

    Settings.all
    # => { 'admin_password' => 'super_secret', 'date_format' => '%m %d, %Y' }

If you want to group settings and list the settings for a particular
namespace, then choose your preferred namespace delimiter and use
`Settings.all` like this:

    Settings['preferences.color'] = :blue
    Settings['preferences.size'] = :large
    Settings['license.key'] = 'ABC-DEF'
    Settings.all('preferences.')
    # => { 'preferences.color' => :blue, 'preferences.size' => :large }

You can set defaults for certain settings of your app.  This will cause the
defined settings to return with the specified value even if they are not in
Redis.  Make a new file in config/initializers/settings.rb with the following:

    Settings.defaults[:some_setting] = 'footastic'
  
Now even if there are not settings in Redis, the app will have some
intelligent defaults:

    Settings.some_setting
    # => 'footastic'

For better performance, you can enable caching, e.g.:

    Settings.cache = ActiveSupport::Cache::MemoryStore.new
    Settings.cache_options = { :expires_in => 5.minutes }
