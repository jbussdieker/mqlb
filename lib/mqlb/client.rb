require "mqlb/client/connection"
require 'bunny'
require 'net/http'
require "http/parser"

module Mqlb
  module Client
    def self.run
      conn = Bunny.new
      conn.start
      conn.exchange('outgoing_response', :type => :direct)
      conn.exchange('incoming_request', :type => :direct)
      conn.queue('requests').bind('incoming_request')

      conn.queue('requests').subscribe(:block => true, :header => true) do |delivery_info, properties, payload|
        #p delivery_info

        parser = Http::Parser.new
        parser << payload

        host, port = parser.headers["Host"].split(":", 2)
        port ||= 80

        EM::run do
          Connection.connect(host, payload) do |raw_response, parsed_response|
            conn.exchange('outgoing_response').publish(raw_response, :key => properties[:reply_to])
            EM::stop
          end
        end
      end
    end
  end
end
