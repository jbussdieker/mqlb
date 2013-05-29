require 'bunny'
require 'net/http'
require "http/parser"

module Mqlb
  module Client
    def self.run
      $conn = Bunny.new
      $conn.start
      $conn.exchange('outgoing_response', :type => :direct)
      $conn.exchange('incoming_request', :type => :direct)
      $conn.queue('requests').bind('incoming_request')

      $conn.queue('requests').subscribe(:block => true, :header => true) do |delivery_info, properties, payload|
        parser = Http::Parser.new
        parser << payload
        p delivery_info

        host, port = parser.headers["Host"].split(":", 2)
        port ||= 80
        client = Net::HTTP.new(host, port)

        method = Net::HTTP.const_get(parser.http_method.capitalize)
        req = method.new(parser.request_url)

        resp = client.request(req)

        resp_raw = ""
        resp_raw << "HTTP/#{resp.http_version} #{resp.code} #{resp.message}\r\n"
        resp.each_capitalized do |key,value|
          resp_raw << "#{key}: #{value}\r\n"
        end

        resp_raw << "\r\n"
        if resp.body != nil
          resp_raw << resp.body
        end

        #resp = "HTTP/1.0 200 OK\r\n\r\nOK"

        $conn.exchange('outgoing_response').publish(resp_raw, :key => properties[:reply_to])
      end
    end
  end
end
