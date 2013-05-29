module Mqlb
  module Server
    class Request
      def initialize(connection, raw_data)
        @dsconnection = connection
        @raw_data = raw_data
      end

      def connection
        return @connection if @connection
        @connection = Bunny.new
        @connection.start
        @connection.exchange('outgoing_response', :type => :direct)
        @connection.exchange('incoming_request', :type => :direct)
        @connection
      end

      def response_queue
        return @response_queue if @response_queue
        @response_queue = connection.queue
        @response_queue.bind('outgoing_response', :routing_key => @response_queue.name)
      end

      def issue_request
        connection.exchange('incoming_request').publish(@raw_data, :reply_to => response_queue.name)
        response_queue.subscribe do |delivery_info, properties, payload|
          #p delivery_info
          @dsconnection.send_data payload
          @dsconnection.close_connection_after_writing
          response_queue.delete
          connection.close
        end
      end
    end
  end
end
