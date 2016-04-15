require 'faraday'
require 'yaml'
require 'base64'
require 'json'
require 'time'
require 'pp'

@url_prefix = 'https://api.github.com'
@conn = Faraday.new(url: @url_prefix) do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger 
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

config = YAML.load_file('./configs/github.yml')

@user        =  config['user']
@password    =  config['password']
@credentials =  Base64.encode64("%s:%s" % [@user, @password])
@basic_auth  =  "Basic %s" % @credentials
@another_user = config['another_user']
@repo_name = config['repo_name']
@target_current_user = 'user/orgs'
@target_another_user = "users/#{@another_user}/orgs"
@commits_since_endpoint = "repos/#{@user}/#{@repo_name}/commits"
#@since = '2016-04-15T01:00:00Z'
@since = (Time.now - 3600).iso8601

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

#execute_request(:get, @target_current_user, {})
#execute_request(:get, @target_another_user, {})
execute_request(:get, @commits_since_endpoint, since: @since)