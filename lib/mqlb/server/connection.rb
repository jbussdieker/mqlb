require 'eventmachine'
require 'bunny'
require "http/parser"

module Mqlb
  module Server
    class Connection < EM::Connection
      def log(msg)
        puts "#{remote_host}: #{msg}"
      end

      def receive_data(data)
        log "Received #{data.length} bytes"
        @raw_data << data
        @parser << data
      end

      def remote_host
        @remote_host ||= Socket.unpack_sockaddr_in(get_peername).reverse.join(":")
      end

      def post_init
        log "Connection opened"

        @raw_data = ""
        @parser = Http::Parser.new
        @parser.on_message_complete = proc do |env|
          issue_request
        end
      end

      def unbind
        log "Connection closed"
      end

      def issue_request
        log "Issuing upstream request for #{@parser.headers["Host"]}"

        req = Request.new(self, @raw_data)
        req.issue_request
      end
    end
  end
end
