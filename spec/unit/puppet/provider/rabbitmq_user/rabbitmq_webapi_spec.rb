require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_user).provider(:rabbitmq_webapi)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_user.new(
      {:name => 'foo', :password => 'bar'}
    )
    Kernel.system 'sudo rabbitmqctl stop_app 2>&1 > /dev/null'
    Kernel.system 'sudo rabbitmqctl reset 2>&1 > /dev/null'
    Kernel.system 'sudo rabbitmqctl start_app 2>&1 > /dev/null'
    @provider = provider_class.new(@resource)
  end
  it 'should create user and set password' do
    @provider.create
    @provider.exists?.should be_true
  end
  it 'shoud create user, set password and set to admin' do
    @resource[:admin] = 'true'
    @provider.create
    @provider.admin.should be_true
  end
  it 'should delete user' do
    @provider.create
    @provider.destroy
  end
  it 'should be able to set/retrieve admin value' do
    @resource[:admin] = 'true'
    @provider.create
    @provider.admin.should be_true
    @resource[:admin] = 'false'
    @provider.create
    @provider.admin.should be_false
  end
  it 'should fail if checking admin on a user that doesn\'t exist' do
    expect { @provider.admin }.to raise_error(Puppet::Error, /Attempted to determine property of non-existent user:/)
  end
  it 'should should return false if user doesn\'t exist' do
    @resource[:name] = 'I_DONT_EXIST'
    @provider.exists?.should be_false
  end
  it 'should be able to set password using password_hash' do
    hash = 'aTYeZuDqw9cUo/RH4US354vkcxo='
    @resource.delete(:password)
    @resource[:password_hash] = hash
    @provider.create
    @provider.get_user[:body]['password_hash'].should == hash
  end
  it 'should default to password hash if hash and string are both given' do
    hash = 'aTYeZuDqw9cUo/RH4US354vkcxo='
    @resource[:password_hash] = hash
    @provider.create
    @provider.get_user[:body]['password_hash'].should == hash
  end
end
