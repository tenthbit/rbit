require 'socket'
require 'openssl'
require 'json'

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

      @auth = {}

      instance_eval(&block)
    end

    def auth(method, data)
      @auth[method] = data
    end

    def auth_password(username, password)
      auth('password', {username: username, password: password})
    end

    def run
      @ssl_socket.connect
      run_loop
    end

    def run!
      Thread.new { run }
    end

    private

    def run_loop
      loop do
        raw_packet = @ssl_socket.gets
        packet = JSON.parse(raw_packet, symbolize_names: true)

        p packet

        case packet[:op]
        when 'welcome'
          authenticate(packet[:ex][:auth])
        end
      end
    end

    def send(packet)
      raw_packet = JSON.dump(packet)
      @ssl_socket.puts(raw_packet)
    end

    def authenticate(methods)
      @auth.each do |method, data|
        next unless methods.include? method
        return send({op: 'auth', ex: {method: method}.merge(data)})
      end
    end
  end
end
