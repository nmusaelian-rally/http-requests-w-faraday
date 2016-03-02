require 'faraday'
require 'base64'
require 'yaml'
require 'json'
require 'pp'

config = YAML.load_file('./configs/tfs.yml')

@user     = config['user']
@password = config['password']
@base_url = config['server']

@credentials = Base64.encode64("%s:%s" % [@user, @password])
@basic_auth = "Basic %s" % @credentials

@projects_endpoint = '_apis/projects'
@workitem_types_endpoint = 'Integrations/_apis/wit/workitemtypes'
@bug_type_endpoint = 'Integrations/_apis/wit/workitemtypes/bug'
@workitems_endpoint = '_apis/wit/workitems'
@folder_creation_endpoint = 'Integrations/_apis/wit/queries/My%20Queries'

klampakis_id = "0f13a664-1a49-44e0-ba8b-dc5253dadb6a"
@query_creation_endpoint = "Integrations/_apis/wit/queries/#{klampakis_id}"
query_wiql = "Select [System.Id], [System.Title], [System.State] From WorkItems Where [System.WorkItemType] = 'Bug' AND [System.TeamProject] = 'ToxicSludge' order by [Microsoft.VSTS.Common.Priority] asc, [System.CreatedDate] desc"


limited_query_wiql = "Select [System.Id], [System.Title], [System.State] From WorkItems Where [System.WorkItemType] = 'Bug' AND [System.TeamProject] = 'Integrations' AND [Microsoft.VSTS.Scheduling.StoryPoints] = '' order by [Microsoft.VSTS.Common.Priority] asc, [System.CreatedDate] desc"


rally_query_wiql = "Select [System.Id], [System.Title], [System.State] From WorkItems Where [System.WorkItemType] = 'Bug' AND [System.TeamProject] = 'Integrations' AND [Rally.Common.ExternalId] = '' order by [Microsoft.VSTS.Common.Priority] asc, [System.CreatedDate] desc"

story_fields_wiql =  "Select [System.Id] From WorkItems Where [System.WorkItemType] = 'Bug'order by [Microsoft.VSTS.Common.Priority] asc, [System.CreatedDate] desc"

story_owner_wiql = "Select [System.Id], [System.Title], [System.State] From WorkItems Where [System.WorkItemType] = 'Bug' AND [System.TeamProject] = 'Integrations' AND [System.AssignedTo] = 'integrations' order by [System.CreatedDate] desc"
story_query_wiql = "Select [System.Id], [System.Title], [System.State] From WorkItems Where [System.WorkItemType] = 'Bug' AND [System.TeamProject] = 'Integrations' AND [Rally.Common.ExternalId] = '' order by [Microsoft.VSTS.Common.Priority] asc, [System.CreatedDate] desc"


@wiql_endpoint = "_apis/wit/wiql"
#@moonshine_query = query_wiql
@moonshine_query = limited_query_wiql
# @rally_query     = rally_query_wiql
@named_fields_query = story_fields_wiql
@story_owner_query = story_query_wiql

@query_retrieval = "Integrations/_apis/wit/queries/My%20Queries/klampakis-the-mistaken-items?"


def create_connection(base_url)
  @conn = Faraday.new(:url => base_url) do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.response :logger                  # log requests to STDOUT
    faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end
end

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

  #@logger.debug(self, payload) if not payload.nil?
  puts (payload) if not payload.nil?
end

create_connection(@base_url)
#execute_request(:get, @projects_endpoint, {api_version: 1.0})
#execute_request(:get, @workitem_types_endpoint, {api_version: 1.0})
#execute_request(:get, @bug_type_endpoint, {api_version: 1.0})
#execute_request(:get, @workitems_endpoint, {api_version: 1.0, ids: "3,4"})
#execute_request(:post, @folder_creation_endpoint, {"api-version" => "1.0"}, {"name" => 'klampakis-the-mistaken-items', "isFolder" => true})
#execute_request(:get, @query_retrieval, {"api-version" => "1.0"})
#execute_request(:post, @query_creation_endpoint, {"api-version" => "1.0"}, query_data)
#execute_request(:post, @wiql_endpoint, {"api-version" => "1.0"}, {"query" => @moonshine_query})
#execute_request(:post, @wiql_endpoint, {"api-version" => "1.0"}, {"query" => @moonshine_query})
#execute_request(:post, @wiql_endpoint, {"api-version" => "1.0"}, {"query" => @rally_query_data})
#execute_request(:post, @wiql_endpoint, {"api-version" => "1.0"}, {"query" => rally_query_wiql})
#execute_request(:post, @wiql_endpoint, {"api-version" => "1.0"}, {"query" => story_owner_wiql})
#execute_request(:get, @workitems_endpoint, {"api-version" => "1.0", :ids => "4,5,6,7", :fields => "System.Id,System.State,System.Title,Microsoft.VSTS.Scheduling.StoryPoints"})
execute_request(:get, @workitems_endpoint, {api_version: 1.0, ids: "3,4,7", :fields => "System.Id,System.State,System.Title,Microsoft.VSTS.Scheduling.StoryPoints,Rally.Common.ExternalID"})