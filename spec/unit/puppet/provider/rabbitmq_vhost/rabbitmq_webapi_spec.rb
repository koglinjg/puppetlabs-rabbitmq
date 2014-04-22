# encoding: utf-8
require 'puppet'
provider_class = Puppet::Type.type(:rabbitmq_vhost).provider(:rabbitmq_webapi)
describe provider_class do
  before :each do
    Kernel.system 'sudo rabbitmqctl stop_app 2>&1 > /dev/null'
    Kernel.system 'sudo rabbitmqctl reset 2>&1 > /dev/null'
    Kernel.system 'sudo rabbitmqctl start_app 2>&1 > /dev/null'
    @resource = Puppet::Type::Rabbitmq_vhost.new({
      :name => 'foo'
    })
    @provider = provider_class.new(@resource)
  end
  it 'should find existing vhost' do
    @resource[:name] = '/'
    @provider.exists?.should be_true
  end
  it 'should return false if vhost doesn\'t exist' do
    @provider.exists?.should be_false
  end
  it 'should create vhost' do
    @provider.create
    @provider.exists?.should be_true
  end
  it 'should create vhost with multibyte characters' do
    @resource[:name] = 'Æthere'
    @provider.create
    @provider.exists?.should be_true
  end
    it 'should create vhost with special characters' do
    @resource[:name] = 'My/Vhost'
    @provider.create
    @provider.exists?.should be_true
  end
  it 'should delete vhost' do
    @provider.create
    @provider.destroy
    @provider.exists?.should be_false
  end
  it 'should delete vhost with multibyte characters' do
    @resource[:name] = 'Æthere'
    @provider.create
    @provider.destroy
    @provider.exists?.should be_false
  end
  it 'should delete vhost with special characters' do
    @resource[:name] = 'My/Vhost'
    @provider.create
    @provider.destroy
    @provider.exists?.should be_false
  end
end
