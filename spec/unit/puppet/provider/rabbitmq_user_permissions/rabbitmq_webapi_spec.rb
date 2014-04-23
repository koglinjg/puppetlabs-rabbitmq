# encoding: utf-8
require 'puppet'
provider_class = Puppet::Type.type(:rabbitmq_user_permissions).provider(:rabbitmq_webapi)
describe provider_class, :webapi_user_permissions => true do
  before :each do
    Kernel.system 'sudo rabbitmqctl stop_app 2>&1 > /dev/null'
    Kernel.system 'sudo rabbitmqctl reset 2>&1 > /dev/null'
    Kernel.system 'sudo rabbitmqctl start_app 2>&1 > /dev/null'
    @resource = Puppet::Type::Rabbitmq_user_permissions.new({
      :name => 'foo@bar'
    })
    @provider = provider_class.new(@resource)
    @user_resource = Puppet::Type::Rabbitmq_user.new({
      :name => 'foo',
      :password => 'foo'
    })
    @user_provider = Puppet::Type.type(:rabbitmq_user).provider(:rabbitmq_webapi)
    @vhost_resource = Puppet::Type::Rabbitmq_vhost.new({
      :name => 'bar'
    })
    @vhost_provider = Puppet::Type.type(:rabbitmq_vhost).provider(:rabbitmq_webapi)
  end
  describe 'exists?' do
    it 'should return true if user has any permissions for vhost' do
      @resource[:name] = 'guest@/'
      @provider.exists?.should be_true
    end
    it 'should throw an error if user has no permissions for vhost' do
      @user_provider.new(@user_resource).create
      expect { @provider.exists? }.to raise_error(Puppet::Error, /User permissions not found for vhost/)
    end
    it 'should throw an error if the user doesn\'t exist' do
      expect { @provider.exists? }.to raise_error(Puppet::Error, /Failed to retrieve user permissions:/)
    end
    it 'should throw an error if the vhost doesn\'t exist' do
      @user_provider.new(@user_resource).create
      expect { @provider.exists? }.to raise_error(Puppet::Error, /User permissions not found for vhost/)
    end
    it 'should handle user names with special characters' do
      @user_resource[:name]='(foo/*bar)'
      @user_provider.new(@user_resource).create
      @vhost_provider.new(@vhost_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @provider.create
      @provider.exists?.should be_true
    end
    it 'should handle vhost names with special characters' do
      @vhost_resource[:name]='(foo/*bar)'
      @vhost_provider.new(@vhost_resource).create
      @user_provider.new(@user_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @provider.create
      @provider.exists?.should be_true
    end
    it 'should handle user names with multibyte characters' do
      @user_resource[:name]='Æthere'
      @user_provider.new(@user_resource).create
      @vhost_provider.new(@vhost_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @provider.create
      @provider.exists?.should be_true
    end
    it 'should handle vhost names with multibyte characters' do
      @vhost_resource[:name]='Æthere'
      @vhost_provider.new(@vhost_resource).create
      @user_provider.new(@user_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @provider.create
      @provider.exists?.should be_true
    end

  end
  describe 'properties' do
    [:configure_permission, :write_permission, :read_permission].each do |k|
      it "should be able to retrieve #{k}" do
        @resource[:name] = 'guest@/'
        @provider.send(k).should == '.*'
      end
      it "should be able to set #{k}" do
        method = "#{k}=".to_sym
        @resource[:name] = 'guest@/'
        @resource[k] = '.foo'
        @provider.send(method,'this expects a trash arg')
        @provider.send(k).should == @resource[k]
      end
    end
  end
  describe 'create' do
    it 'should be able to create new user permissions' do
      @user_provider.new(@user_resource).create
      @vhost_provider.new(@vhost_resource).create
      @resource[:read_permission]='.foo'
      @resource[:write_permission]='.foo'
      @resource[:configure_permission]='.foo'
      @provider.create
      @provider.read_permission.should == '.foo'
      @provider.write_permission.should == '.foo'
      @provider.configure_permission.should == '.foo'
    end
    it 'should be able to update a users existing permissions', :focus => true do
      @resource[:name]='guest@/'
      @resource[:read_permission]='.foo'
      @resource[:write_permission]='.foo'
      @resource[:configure_permission]='.foo'
      @provider.create
      @provider.read_permission.should == '.foo'
      @provider.write_permission.should == '.foo'
      @provider.configure_permission.should == '.foo'
    end
    it 'should handle user names with special characters' do
      @user_resource[:name]='(foo/*bar)'
      @user_provider.new(@user_resource).create
      @vhost_provider.new(@vhost_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @resource[:read_permission]='.foo'
      @resource[:write_permission]='.foo'
      @resource[:configure_permission]='.foo'
      @provider.create
      @provider.read_permission.should == '.foo'
      @provider.write_permission.should == '.foo'
      @provider.configure_permission.should == '.foo'
    end
    it 'should handle vhost names with special characters' do
      @user_provider.new(@user_resource).create
      @vhost_resource[:name]='(foo/*bar)'
      @vhost_provider.new(@vhost_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @resource[:read_permission]='.foo'
      @resource[:write_permission]='.foo'
      @resource[:configure_permission]='.foo'
      @provider.create
      @provider.read_permission.should == '.foo'
      @provider.write_permission.should == '.foo'
      @provider.configure_permission.should == '.foo'
    end
    it 'should handle user names with multi byte characters' do
      @user_resource[:name]='Æthere'
      @user_provider.new(@user_resource).create
      @vhost_provider.new(@vhost_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @resource[:read_permission]='.foo'
      @resource[:write_permission]='.foo'
      @resource[:configure_permission]='.foo'
      @provider.create
      @provider.read_permission.should == '.foo'
      @provider.write_permission.should == '.foo'
      @provider.configure_permission.should == '.foo'
    end
    it 'should handle vhost names with multibyte characters' do
      @user_provider.new(@user_resource).create
      @vhost_resource[:name]='Æthere'
      @vhost_provider.new(@vhost_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @resource[:read_permission]='.foo'
      @resource[:write_permission]='.foo'
      @resource[:configure_permission]='.foo'
      @provider.create
      @provider.read_permission.should == '.foo'
      @provider.write_permission.should == '.foo'
      @provider.configure_permission.should == '.foo'
    end
    it 'should throw an error when the user doesn\'t exist' do
      @vhost_provider.new(@vhost_resource).create
      expect { @provider.create }.to raise_error(Puppet::Error, /reasonvhost_or_user_not_found/)
    end
    it 'should throw an error when the vhost doesn\'t exist' do
      @user_provider.new(@user_resource).create
      expect { @provider.create }.to raise_error(Puppet::Error, /reasonvhost_or_user_not_found/)
    end
    it 'should fallback to default permissions when a permission value is undef' do
      @user_provider.new(@user_resource).create
      @vhost_provider.new(@vhost_resource).create
      @resource[:name]="#{@user_resource[:name]}@#{@vhost_resource[:name]}"
      @provider.create
      @provider.read_permission.should == ''
      @provider.write_permission.should == ''
      @provider.configure_permission.should == ''
    end
  end
end
