require 'puppet'
begin
  require '../../../helpers/rabbitmq_webapi_provider_helper' # 1.9.2 +
rescue LoadError
  require File.join(File.dirname(__FILE__), '../../../helpers/rabbitmq_webapi_provider_helper') # < 1.9.2
end

Puppet::Type.type(:rabbitmq_vhost).provide(:rabbitmq_webapi) do

  def vhosts
    unless @vhosts
      api = self.api
      response = api.get({
        :uri => '/api/vhosts'
      })
      if api.success? response[:code]
        @vhosts = response[:body].inject({}){|k,v| k[v['name']] = v; k }
      else
        raise Puppet::Error, "Failed to retrieve vhosts: #{response[:code]} #{response[:body]}"
      end
    end
    return @vhosts
  end

  def create
    api = self.api
    response = api.put({
      :uri => '/api/vhosts/%s',
      :uri_vars => [@resource[:name]]
    })
    unless api.success? response[:code]
      raise Puppet::Error, "Failed to create vhost: #{response[:code]} #{response[:body]}"
    end
  end

  def destroy
    api = self.api
    response = api.delete({
      :uri => '/api/vhosts/%s',
      :uri_vars => [@resource[:name]]
    })
    unless api.success? response[:code]
      raise Puppet::Error, "Failed to delete vhost: #{response[:code]} #{response[:body]}"
    end
  end

  def exists?
    self.vhosts.has_key? @resource[:name]
  end
  
  def api
    @api ||= Rabbitmq_webapi.new
  end

end
