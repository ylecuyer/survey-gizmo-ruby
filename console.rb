$:.unshift './lib'
require "./lib/survey-gizmo-ruby"

require "net-http-spy"

def auth_query(opts = {})
  {:query => {"user:pass" =>  "jonathan@sandboxindustries.com:sandbox213"}.merge(opts)}
end

Net::HTTP.http_logger_options = {:verbose => true, :body => true}

