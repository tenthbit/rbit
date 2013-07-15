require 'rbit/logger'

require 'socket'
require 'openssl'
require 'json'

module Rbit
  class Connection
    ProtocolError = Class.new(StandardError)

    PROTOCOL = '10bit'

    def initialize(host, port = 10817, logger_file = STDOUT, logger_level = Logger::INFO)
      @logger = Logger.new(logger_file, logger_level)
      @logger.debug 'Logger initialized'

      @logger.info "Connecting to #{host}:#{port}"
      @tcp_socket = TCPSocket.new(host, port)

      ssl_context = OpenSSL::SSL::SSLContext.new
      if ssl_context.respond_to? :npn_select_cb # Only available in Ruby 2.0
        ssl_context.npn_select_cb = proc do |protos|
          @logger.debug "Server NPN list: #{protos.join(', ')}"
          raise ProtocolError, "Server does not support #{PROTOCOL}" unless protos.include? PROTOCOL
          PROTOCOL
        end
      end
      @ssl_socket = OpenSSL::SSL::SSLSocket.new(@tcp_socket, ssl_context)

      @handlers = {}
    end

    def add_handler(op, handler)
      @logger.debug "Adding handler for #{op}: #{handler}"

      @handlers[op] ||= []
      @handlers[op] << handler
    end

    def send(packet)
      @logger.out packet

      raw_packet = JSON.dump(packet)
      @ssl_socket.puts(raw_packet)
    end

    def run
      @logger.info 'Performing SSL handshake'
      @ssl_socket.connect
      @logger.info 'Connected'

      loop do
        raw_packet = @ssl_socket.gets
        packet = JSON.parse(raw_packet, symbolize_names: true)

        @logger.in packet

        @handlers.fetch(packet[:op], []).each do |handler|
          Thread.new { handler[self, packet] }
        end
      end
    end

    def run!
      Thread.new { run }
    end
  end
end
