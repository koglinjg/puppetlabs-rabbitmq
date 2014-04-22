require 'puppet'
begin
  require '../../../helpers/rabbitmq_webapi_provider_helper' # 1.9.2 +
rescue LoadError
  require File.join(File.dirname(__FILE__), '../../../helpers/rabbitmq_webapi_provider_helper') # < 1.9.2
end

Puppet::Type.type(:rabbitmq_user_permissions).provide(:rabbitmq_webapi) do

  # cache users permissions
  def users(name, vhost)
    @users = {} unless @users
    unless @users[name]
      @users[name] = {} 
      api = self.api
      response = api.get(
        :uri=>'/api/users/%s/permissions',
        :uri_vars=>[name]
        )
      if api.success? response[:code]
        permissions = response[:body].inject({}){|k,v| k[v['vhost']] = v; k }
        @users[name] = permissions
      else
        raise Puppet::Error, "Failed to retrieve user permissions: #{response[:code]} #{response[:body]}"
      end
    end
    raise Puppet::Error, 'User permissions not found in cache' if @users[name].nil?
    raise Puppet::Error, "User permissions not found for vhost '#{vhost}' in cache" if @users[name][vhost].nil?
    @users[name][vhost]
  end

  def should_user
    @should_user ||= resource[:name].split('@')[0]
  end

  def should_vhost
    @should_vhost ||= resource[:name].split('@')[1]
  end

  def defaults
    @defaults ||= {
        :configure_permission => '',
        :read_permission => '',
        :write_permission => ''
    }
  end

  def create
    resource[:configure_permission] ||= defaults[:configure_permission]
    resource[:read_permission]      ||= defaults[:read_permission]
    resource[:write_permission]     ||= defaults[:write_permission]
    vhost = self.should_vhost
    user = self.should_user
    api = self.api
    @users.delete user unless @users.nil? || @users[user].nil?
    response = api.put(
      :uri => '/api/permissions/%s/%s',
      :uri_vars => [vhost,user],
      :data => {
        :configure => resource[:configure_permission],
        :read => resource[:read_permission],
        :write => resource[:write_permission]
      }
    )
    unless @api.success? response[:code]
      raise Puppet::Error, "Failed to create user permissions: #{response[:code]} #{response[:body]}"
    end
  end

  def destroy
    vhost = self.should_vhost
    user = self.should_user
    @api = self.api
    @users.delete user if @users[user]
    response = @api.delete(
      :uri => '/api/permissions/%s/%s',
      :uri_vars => [vhost,user]
    )
    unless @api.success? response[:code]
      raise Puppet::Error, "Failed to delete user permissions: #{response[:code]} #{response[:body]}"
    end
  end

  def exists?
    users(should_user, should_vhost)
  end

  def configure_permission
    users(should_user, should_vhost)['configure']
  end

  def configure_permission=(perm)
    set_permissions
  end

  def read_permission
    users(should_user, should_vhost)['read']
  end

  def read_permission=(perm)
    set_permissions
  end

  def write_permission
    users(should_user, should_vhost)['write']
  end

  def write_permission=(perm)
    set_permissions
  end

  # implement memoization so that we only call set_permissions once
  def set_permissions
    unless @permissions_set
      @permissions_set = true
      if self.exists?.nil?
        resource[:configure_permission] ||= defaults[:configure_permission]
        resource[:read_permission]      ||= defaults[:read_permission]
        resource[:write_permission]     ||= defaults[:write_permission]
      else
        resource[:configure_permission] = resource[:configure_permission] || configure_permission || defaults[:configure_permission]
        resource[:read_permission]      = resource[:read_permission]      || read_permission      || defaults[:read_permission]
        resource[:write_permission]     = resource[:write_permission]     || write_permission     || defaults[:write_permission]
      end
      self.create
    end
  end
  
  def api
    @api ||= Rabbitmq_webapi.new
  end

end