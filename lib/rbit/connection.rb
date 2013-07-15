require 'socket'
require 'openssl'

module Rbit
  class Connection
    ProtocolError = Class.new(StandardError)

    PROTOCOL = '10bit'

    def initialize(host, port = 10817, &block)
      @tcp_socket = TCPSocket.new(host, port)

      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.npn_select_cb = proc do |protos|
        # TODO: Log somewhere what protocols are supported?
        unless protos.include? PROTOCOL
          raise ProtocolError, "Server does not support protocol #{PROTOCOL}"
        end
        PROTOCOL
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
