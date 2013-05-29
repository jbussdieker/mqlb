require 'eventmachine'
require "http/parser"

module Mqlb
  module Client
    class Connection < EM::Connection
      attr_accessor :request_data, :callback, :host

      def self.connect(host, data, port = 80, ssl=false, &callback)
        EventMachine.connect(host, port, self, host, data, callback)
      end

      def initialize(host, data, callback)
        @host = host
        @request_data = data
        @callback = callback
      end

      def log(msg)
        puts "#{remote_host}: #{msg}"
      end

      def receive_data(data)
        #log "Received #{data.length} bytes"
        @raw_data << data
        @parser << data
      end

      def remote_host
        @host
      end

      def post_init
        log "Connection opened"

        @raw_data = ""
        @parser = Http::Parser.new
        @parser.on_message_complete = proc do |env|
          @callback.call(@raw_data, @parser)
        end
      end

      def connection_completed
        send_data @request_data
      end

      def unbind
        log "Connection closed"
      end
    end
  end
end
