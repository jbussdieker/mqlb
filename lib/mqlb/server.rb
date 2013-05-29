require "mqlb/server/connection"
require "mqlb/server/request"
require 'eventmachine'

module Mqlb
  module Server
    def self.run
      EM.run do
        EM.start_server '0.0.0.0', 8080, Connection
      end
    end
  end
end
