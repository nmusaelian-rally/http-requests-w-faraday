require 'faraday'
require 'yaml'
require 'base64'
require 'json'
require 'pp'

config = YAML.load_file('./configs/rally.yml')
apikey = config['apikey']
workspace = config['workspace'].to_s

conn = Faraday.new(:url => 'https://rally1.rallydev.com/slm/webservice/v2.0') do |faraday|
  faraday.request  :url_encoded             
  faraday.response :logger                  
  faraday.adapter  Faraday.default_adapter  
end

## POST ##


res = conn.post do |req|
  req.url 'defect/create?workspace=/workspace/' + workspace
  req.headers['Content-Type'] = 'application/json'
  req.headers['zsessionid'] = apikey
  req.body = '{ "defect":{"name": "bad defect F"} }'
end

parsed = JSON(res.body)
oid = parsed["CreateResult"]["Object"]["ObjectID"]
p oid




