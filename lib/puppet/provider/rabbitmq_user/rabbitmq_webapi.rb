require 'puppet'
begin
  require '../../../helpers/rabbitmq_webapi_provider_helper' # 1.9.2 +
rescue LoadError
  require File.join(File.dirname(__FILE__), '../../../helpers/rabbitmq_webapi_provider_helper') # < 1.9.2
end

Puppet::Type.type(:rabbitmq_user).provide(:rabbitmq_webapi) do

  def exists?
    api = self.api
    response = self.get_user
	if api.success? response[:code]
	  return true
    elsif response[:code] == 404
	  return false
	else
	  raise Puppet::Error, "Failed to lookup user: #{response[:code]} #{response[:body]}"
	end
  end

  def create
    api = self.api
    data = {}
	if resource[:password_hash]
	  data[:password_hash] = resource[:password_hash]
	elsif resource[:password]
	  data[:password] = resource[:password]
	end
	if resource[:admin] == :true
	  data[:tags] = "administrator"
	else
	  data[:tags] = resource[:name]
	end
    response = api.put({
	  :uri => "/api/users/#{resource[:name]}",
	  :data => data
	})
	unless api.success? response[:code]
	  raise Puppet::Error, "Failed to create user: #{response[:code]} #{response[:body]}"
	end
  end

  def destroy
    api = self.api
    response = api.delete({
	  :uri => "/api/users/#{resource[:name]}",
	})
	unless api.success? response[:code]
	  raise Puppet::Error, "Failed to delete user: #{response[:code]} #{response[:body]}"
	end
  end
  
  def api
    @api ||= Rabbitmq_webapi.new
  end
  
  def admin
    api = self.api
	response = get_user
	tags = response[:body]['tags'].split(',')
	if tags.include?('administrator')
	  return :true
	else
	  return :false
	end
  end
  
  def admin=(state)
	self.create
  end
  
  def get_user
    api = self.api
    response = api.get({
	  :uri => "/api/users/#{resource[:name]}"
	})
  end

end