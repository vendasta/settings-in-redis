require 'spec_helper'

describe Settings do
  shared_examples_for 'settings in redis' do
    before(:each) do
      Settings.delete_all
    end

    describe '.delete_all' do
      it 'removes all settings from Redis' do
        Settings.hello = 'first'
        Settings.delete_all
        expect(Settings.all).to be_empty
      end
    end

    describe '.all' do
      it 'returns all settings as a hash' do
        Settings.one = 1
        Settings.two = 2

        expect(Settings.all).to eq(
            { 'one' => 1, 'two' => 2 }
        )
      end

      context 'when starting_with is specified' do
        it 'returns matching settings' do
          Settings.test = 'foo'
          Settings['sub.one'] = 'bar'
          Settings['sub.two'] = 'baz'
          expect(Settings.all('sub')).to eq(
              { 'sub.one' => 'bar', 'sub.two' => 'baz' }
          )
        end
      end
    end

    describe '.defaults' do
      context 'default string value' do
        before(:each) do
          Settings.defaults[:foo] = 'default foo'
        end

        it 'returns the default for an unset Setting' do
          expect(Settings.foo).to eq('default foo')
        end

        it 'does not return the default is set explicitly' do
          Settings.foo = 'bar'
          Settings.all
          expect(Settings.foo).to eq('bar')
        end
      end

      it 'supports a default of true' do
        Settings.defaults[:foo] = true
        expect(Settings.foo).to eq(true)
      end

      it 'supports a default of false' do
        Settings.defaults[:foo] = false
        expect(Settings.foo).to eq(false)
      end
    end

    describe '.defaults=' do
      it 'sets all defaults' do
        Settings.defaults = HashWithIndifferentAccess.new(foo: 'one', bar: 'two')
        expect(Settings.foo).to eq('one')
        expect(Settings.bar).to eq('two')
      end
    end

    context 'set a setting' do
      context 'set using []' do
        it 'sets a setting using the [] syntax with a string' do
          Settings['test2'] = 456
          expect(Settings.all['test2']).to eq(456)
        end

        it 'sets a setting using the [] syntax with a symbol' do
          Settings[:test2] = 'onetwothree'
          expect(Settings.all['test2']).to eq('onetwothree')
        end
      end

      context 'set using method' do
        it 'sets a setting using method missing' do
          Settings.test2 = 456
          expect(Settings.all['test2']).to eq(456)
        end
      end

      context 'updating an existing setting' do
        before(:each) do
          Settings.test = 'foo'
        end

        it 'allows an existing setting to be updated' do
          Settings.test = 123
          expect(Settings.test).to eq(123)
        end
      end

      context 'set a setting to nil' do
        it 'removes the setting' do
          Settings.remove_me = 'something'
          Settings.remove_me = nil
          expect(Settings.all).to eq({ 'remove_me' => nil })
        end
      end

      context 'complex serialization' do
        it 'correctly serializes and deserializes complex values' do
          complex = [1, '2', {:three => true}]
          Settings.complex = complex
          expect(Settings.complex).to eq(complex)
        end
      end

      context 'float serialization' do
        it 'correctly serializes and deserializes floats' do
          Settings.float = 0.01
          expect(Settings.float).to eq(0.01)
          expect(2 * Settings.float).to eq(0.02)
        end
      end
    end

    context 'get a setting' do
      context 'get using []' do
        it 'gets a setting value using the [] syntax with a string' do
          Settings.test = 'foo'
          expect(Settings['test']).to eq('foo')
        end

        it 'gets a setting value using the [] syntax with a symbol' do
          Settings.test = 'foo'
          expect(Settings['test']).to eq('foo')
        end
      end

      context 'get using method' do
        it 'gets a setting value using method missing' do
          Settings[:test] = 'foo'
          expect(Settings.test).to eq('foo')
        end
      end

      context 'get a setting that does not exist' do
        it 'returns nil' do
          expect(Settings.does_not_exist).to be_nil
        end
      end
    end

    describe '.merge!' do
      it 'merges keys into an existing hash value' do
        # Note: [] must be used here
        Settings[:hash] = { :one => 1 }
        Settings.merge!(:hash, { :two => 2 })
        expect(Settings[:hash]).to eq({ :one => 1, :two => 2 })
      end

      it 'creates a new setting if it does not exist already' do
        Settings.merge!(:empty_hash, { :two => 2 })
        expect(Settings.empty_hash).to eq({ :two => 2 })
      end

      it 'raises an error if the value is not a Hash' do
        expect do
          Settings.merge!(:hash, 123)
        end.to raise_error(ArgumentError)
      end

      it 'raises an error if the existing value is not a Hash' do
        Settings.test = 'foo'
        expect do
          Settings.merge!(:test, { :a => 1 })
        end.to raise_error(TypeError)
      end
    end

    describe '.destroy' do
      it 'removes an existing setting' do
        Settings.test = 'foo'
        Settings.test2 = 'bar'
        Settings.destroy('test')
        Settings.destroy(:test2)
        expect(Settings.test).to be_nil
        expect(Settings.test2).to be_nil
      end
    end

    context 'with caching' do
      before(:each) do
        Settings.cache = ActiveSupport::Cache::MemoryStore.new
        Settings.cache_options = { :expires_in => 5.minutes }
      end

      after(:each) do
        Settings.cache = nil
      end

      it 'stores values in cache' do
        Settings.progress = 'boing'
        # Explicitly remove from redis
        # Settings.redis is private, so trying to call it will trigger Settings.method_missing as
        # if we're trying to access a setting called 'redis'.
        Settings.send(:redis) do |redis|
          redis.del('settings:progress')
        end
        expect(Settings.progress).to eq('boing')
        Settings.delete_all # also clears cache
        expect(Settings.progress).to be_nil
      end
    end
  end

  context 'when using a redis connection directly' do
    before(:each) do
      Settings.redis = Redis.new
      Settings.redis_pool = nil
    end

    it_behaves_like 'settings in redis'
  end

  context 'when using a redis connection pool' do
    before(:each) do
      Settings.redis_pool = ConnectionPool.new { Redis.new }
      Settings.redis = nil
    end

    it_behaves_like 'settings in redis'
  end
end