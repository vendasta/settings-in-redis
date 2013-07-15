require 'spec_helper'

describe Settings do
  let(:redis) { Settings.instance_variable_get('@redis') }

  before(:each) do
    Settings.delete_all
  end

  describe '.delete_all' do
    it 'removes all settings from Redis' do
      Settings.hello = 'first'
      Settings.delete_all
      Settings.all.should be_empty
    end
  end

  describe '.all' do
    it 'returns all settings as a hash' do
      Settings.one = 1
      Settings.two = 2

      Settings.all.should ==
          { 'one' => 1, 'two' => 2 }
    end

    context 'when starting_with is specified' do
      it 'returns matching settings' do
        Settings.test = 'foo'
        Settings['sub.one'] = 'bar'
        Settings['sub.two'] = 'baz'
        Settings.all('sub').should ==
            { 'sub.one' => 'bar', 'sub.two' => 'baz' }
      end
    end
  end

  describe '.defaults' do
    context 'default string value' do
      before(:each) do
        Settings.defaults[:foo] = 'default foo'
      end

      it 'returns the default for an unset Setting' do
        Settings.foo.should == 'default foo'
      end

      it 'does not return the default is set explicitly' do
        Settings.foo = 'bar'
        Settings.all
        Settings.foo.should == 'bar'
      end
    end

    it 'supports a default of true' do
      Settings.defaults[:foo] = true
      Settings.foo.should == true
    end

    it 'supports a default of false' do
      Settings.defaults[:foo] = false
      Settings.foo.should == false
    end
  end

  context 'set a setting' do
    context 'set using []' do
      it 'sets a setting using the [] syntax with a string' do
        Settings['test2'] = 456
        Settings.all['test2'].should == 456
      end

      it 'sets a setting using the [] syntax with a symbol' do
        Settings[:test2] = 'onetwothree'
        Settings.all['test2'].should == 'onetwothree'
      end
    end

    context 'set using method' do
      it 'sets a setting using method missing' do
        Settings.test2 = 456
        Settings.all['test2'].should == 456
      end
    end

    context 'updating an existing setting' do
      before(:each) do
        Settings.test = 'foo'
      end

      it 'allows an existing setting to be updated' do
        Settings.test = 123
        Settings.test.should == 123
      end
    end

    context 'set a setting to nil' do
      it 'removes the setting' do
        Settings.remove_me = 'something'
        Settings.remove_me = nil
        Settings.all.should == { 'remove_me' => nil }
      end
    end

    context 'complex serialization' do
      it 'correctly serializes and deserializes complex values' do
        complex = [1, '2', {:three => true}]
        Settings.complex = complex
        Settings.complex.should == complex
      end
    end

    context 'float serialization' do
      it 'correctly serializes and deserializes floats' do
        Settings.float = 0.01
        Settings.float.should == 0.01
        (2 * Settings.float).should == 0.02
      end
    end
  end

  context 'get a setting' do
    context 'get using []' do
      it 'gets a setting value using the [] syntax with a string' do
        Settings.test = 'foo'
        Settings['test'].should == 'foo'
      end

      it 'gets a setting value using the [] syntax with a symbol' do
        Settings.test = 'foo'
        Settings['test'].should == 'foo'
      end
    end

    context 'get using method' do
      it 'gets a setting value using method missing' do
        Settings[:test] = 'foo'
        Settings.test.should == 'foo'
      end
    end

    context 'get a setting that does not exist' do
      it 'returns nil' do
        Settings.does_not_exist.should be_nil
      end
    end
  end

  describe '.merge!' do
    it 'merges keys into an existing hash value' do
      # Note: [] must be used here
      Settings[:hash] = { :one => 1 }
      Settings.merge!(:hash, { :two => 2 })
      Settings[:hash].should == { :one => 1, :two => 2 }
    end

    it 'creates a new setting if it does not exist already' do
      Settings.merge!(:empty_hash, { :two => 2 })
      Settings.empty_hash.should == { :two => 2 }
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
      Settings.test.should be_nil
      Settings.test2.should be_nil
    end
  end

  context 'with caching' do
    before(:each) do
      Settings.cache = ActiveSupport::Cache::MemoryStore.new
      Settings.cache_options = { :expires_in => 5.minutes }
    end

    it 'stores values in cache' do
      Settings.progress = 'boing'
      # Explicitly remove from redis
      redis.del('settings:progress')
      Settings.progress.should == 'boing'
      Settings.delete_all # also clears cache
      Settings.progress.should be_nil
    end
  end
end