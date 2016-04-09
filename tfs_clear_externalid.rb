require 'faraday'
require 'base64'
require 'yaml'
require 'json'
require 'pp'

class TFSConnector
  attr_reader :server, :user, :password, :item_type, :team_project, :connection
  def initialize(config={})
    @server = config['server']
    @user = config['user']
    @password = config['password']
    @team_project = config['team_project']
    @item_type = config['type']
    @credentials = Base64.encode64("%s:%s" % [@user, @password])
    @basic_auth = "Basic %s" % @credentials
  end

  def connect(base_url)
    @connection = Faraday.new(:url => base_url) do |faraday|
      faraday.request  :url_encoded
      faraday.adapter  Faraday.default_adapter
    end
  end

  def make_request(method, target, options={}, data=nil, extra_headers=nil)
    response = @connection.send(method) do |req|
      if !options.empty?
        option_items = options.collect {|key, value| "#{key}=#{value}"}
        target << "?" << option_items.join("&")
      end

      #puts "issuing a #{method.to_s.upcase} request for endpoint: #{target}"

      req.url(target)
      req.headers['Content-Type']  = 'application/json'
      req.headers['Authorization'] = @basic_auth
      if method.to_s.downcase == 'post' && (target =~ /workitems\/\$#{@item_type}/ || target =~ /workitems\/\d+/)
        req.headers['Content-Type'] = 'application/json-patch+json' #even when we override we must keep the original content-type: json-patch+json
        req.headers['X-HTTP-Method-Override'] = 'PATCH'
      end
      if data
        req.body = data.to_json
      end
    end

    result = response.body
    begin
      result = JSON.parse(result.gsub('=>', ':'))
    rescue => e
      puts e.message
    end
    result
  end
end


config = YAML.load_file('./configs/tfs2.yml')
connector = TFSConnector.new(config)

connector.connect(connector.server)

wiql_endpoint = "_apis/wit/wiql"
all_bugs_in_proj_wiql = "Select Id From WorkItems Where [System.WorkItemType] = 'Bug' AND [System.TeamProject] = 'Integrations' order by [System.CreatedDate] desc"
results = connector.make_request(:post,wiql_endpoint,{"api-version" => "1.0"}, {"query" => all_bugs_in_proj_wiql} )
results["workItems"].each do |bug|
  puts ".......#{bug['id']}"
  if bug['id'] > 100
    update_endpoint = "#{connector.server}/_apis/wit/workitems/#{bug['id']}"
    #payload = [{"op" => "remove", "path" => "/fields/Rally.Common.ExternalId"}]
    payload = [{"op" => "remove", "path" => "/fields/Rally.Common.CrosslinkUrl"}]
    connector.make_request(:post, update_endpoint, {"api-version" => "1.0", "$expand" => "relations"}, payload)
  end
end

