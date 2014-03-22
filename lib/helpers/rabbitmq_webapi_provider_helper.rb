require 'net/http'
require 'json'
require 'erb'

class Rabbitmq_webapi

  HTTP_MAP = {
    :get    => Net::HTTP::Get,
    :post   => Net::HTTP::Post,
    :put    => Net::HTTP::Put,
    :delete => Net::HTTP::Delete
  }

  def initialize(args = {})
    host = args[:host] || '127.0.0.1'
	port = args[:port] || '15672'
	@user = args[:user] || 'guest'
	@password = args[:password] || 'guest'
	@http = Net::HTTP.new(host, port)
	self
  end

  def get(args)
    self.request(:get,args)
  end
  
  def post(args)
    self.request(:post,args)
  end
  
  def put(args)
    self.request(:put,args)
  end
  
  def delete(args)
	self.request(:delete,args)
  end
  
  def success?(code)
    code = code
	  if code >= 200 && code < 300
	    return true
	  else
	    return false
    end
  end
  
  def request(method,args)
    if args[:uri_vars]
	  args[:uri_vars].map! { |v| ERB::Util.u(v) }
	  uri = args[:uri] % args[:uri_vars]
	else
	  uri = args[:uri]
	end
	result = {}
    request = HTTP_MAP[method.to_sym].new(uri,initheader = {'Content-Type' =>'application/json'})
	data = args[:data]
	unless data.nil?
	  request.body = JSON.generate(data)
	end
    request.basic_auth(@user,@password)
    #@http.set_debug_output($stdout)
    response = @http.request(request)
	result[:code] = response.code.to_i
	unless result[:code] == 204
	  if response['Content-Type'] == 'application/json'
	    result[:body] = JSON.parse(response.body)
	  else
	    result[:body] = response.body
	  end
	end
	return result
  end

end