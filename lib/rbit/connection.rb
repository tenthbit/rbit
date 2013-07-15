require 'socket'
require 'openssl'

module Rbit
  class Connection
    ProtocolError = Class.new(StandardError)

    PROTOCOL = '10bit'

    def initialize(host, port = 10817, &block)
      @tcp_socket = TCPSocket.new(host, port)

      ssl_context = OpenSSL::SSL::SSLContext.new
      if ssl_context.respond_to?(:npn_select_cb=) # Only available in Ruby 2.0
        ssl_context.npn_select_cb = proc do |protos|
          raise ProtocolError, "Server does not support protocol #{PROTOCOL}" unless protos.include? PROTOCOL
          PROTOCOL
        end
      end
      @ssl_socket = OpenSSL::SSL::SSLSocket.new(@tcp_socket, ssl_context)
    end

    def run
      @ssl_socket.connect
    end

    def run!
      Thread.new { run }
    end
  end
end
