require 'faraday'
require 'yaml'
require 'base64'
require 'json'
require 'pp'

config = YAML.load_file('./configs/rally.yml')

@base_url = 'https://rally1.rallydev.com/slm/webservice/v2.0'

@conn = Faraday.new(url: @base_url) do |faraday|
  faraday.request  :url_encoded             
  faraday.response :logger 
  faraday.adapter  Faraday.default_adapter  
end

@user        = config['user']
@password    = config['password']
@credentials = Base64.encode64("%s:%s" % [@user, @password])
@basic_auth = "Basic %s" % @credentials
@target = 'defect'
@nd_workspace = '/workspace/17465508792'
@query = '(State = Fixed)'
@fetch = 'FormattedID,State'


def execute_request(method, endpoint, options={}, data=nil, extra_headers=nil)
  response = @conn.send(method) do |req|
    if !options.empty?
      option_items = options.collect {|key, value| "#{key}=#{value}"}
      endpoint << "?" << option_items.join("&")
    end

    puts "issuing a #{method.to_s.upcase} request for endpoint: #{endpoint}"

    req.url(endpoint)
    req.headers['Content-Type'] = 'application/json'
    req.headers['Authorization'] = @basic_auth
    if data
      req.body = data.to_json
    end
  end

  payload = response.body
  begin
    payload = JSON.pretty_generate(JSON.parse(payload))
  rescue => e
    puts e.message
  end

  puts (payload) if not payload.nil?
end

execute_request(:get, @target, {workspace: @nd_workspace, fetch: @fetch, query: @query})

