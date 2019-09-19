# frozen_string_literal: true

require 'sinatra'
require 'net/http'
require 'uri'

STORAGE = {}
HOST = 'localhost'
PORTS = [3000, 3001, 3002]

get '/:key' do
  STORAGE[params['key']]
end

post '/:key' do
  (key, value) = [params['key'], request.body.read]

  STORAGE[key] = value

  friend_hosts = PORTS.select { |port| port != request.port }
  friend_hosts.all? do |port|
    uri = URI.parse("http://#{HOST}:#{port}/#{key}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = value
    response = http.request(request)
    response.kind_of? Net::HTTPSuccess
  end
end
