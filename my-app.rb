# frozen_string_literal: true

require 'sinatra'
require 'net/http'
require 'uri'
require 'json'

HOST = 'localhost'
PORTS = [3000, 3001, 3002]
STORAGE = { }

get '/:key' do
  value = define_value
  if value
    value
  else
    status 404
  end
end

# Internal API
post '/replicate/:key' do
  (key, value) = [params['key'], request.body.read]

  update(key, value)
  true
end

get '/:key/with_version' do
  value = STORAGE[params['key']]
  if value
    value.to_json
  else
    status 404
  end
end

post '/:key' do
  (key, value) = [params['key'], request.body.read]

  friend_hosts = PORTS.select { |port| port != request.port }
  error_count = 0

  friend_hosts.each do |port|
    begin
      uri = URI.parse("http://#{HOST}:#{port}/replicate/#{key}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = value
      response = http.request(request)
      error_count += 1 unless response.kind_of? Net::HTTPSuccess
    rescue => e
      error_count += 1
    end
  end

  case error_count
  when 2
    false
  else
    update(key, value)
    true
  end
end

def friend_values
  @friend_values ||= request_values
end

def update(key, value)
  STORAGE[key] = {} unless STORAGE.key?(key)
  STORAGE[key]['value'] = value
  STORAGE[key]['version'] = 0 if STORAGE[key]['version'].nil?
  STORAGE[key]['version'] += 1
end

def request_values
  values = []
  friend_hosts = PORTS.select { |port| port != request.port }
  friend_hosts.each do |port|
    begin
      uri = URI.parse("http://#{HOST}:#{port}/#{params['key']}/with_version")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      values << JSON.parse(response.body) if response.kind_of? Net::HTTPSuccess
    rescue => e
    end
  end

  values
end

def define_value
  return nil if friend_values.count.zero? || STORAGE[params['key']].nil?

  friend_values << STORAGE[params['key']]
  values_by_version = {}
  friend_values.each do |value_and_version|
    values_by_version[value_and_version['version']] = { 'value' => value_and_version['value'], 'count' => 0 } if values_by_version['version'].nil?
    values_by_version[value_and_version['version']]['count'] += 1
  end

  values_by_version.max_by { |k, v| v['count'] }[1]['value']
end
