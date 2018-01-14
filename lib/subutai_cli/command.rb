require 'vagrant'
require 'optparse'
require 'net/https'
require 'io/console'
require 'uri'
require_relative 'config'

module SubutaiCli
  module Subutai
    class Command < Vagrant.plugin('2', :command)
      # show description when `vagrant list-comands` is triggered
      def self.synopsis
        "Vagrant Subutai CLI - executes Subutai scripts in target hosts"
      end

      def execute
        options = {}
        opts = OptionParser.new do |opt|
          opt.banner = "Usage: vagrant subutai --<command> [options]"
          opt.separator ""

          opt.on("-l", "--log", "show snap logs") do
            options[:command] = SubutaiCommands::LOG
          end

          opt.on("-u", "--update NAME", "update Subutai rh or management") do |name|
            options[:command] = SubutaiCommands::UPDATE + " " + name
          end

          opt.on("-r", "--register", "register Subutai Peer to Hub") do
            options[:register] = true
          end
        end

        argv = parse_options(opts)
        return if !argv

        if options[:register]
          login
        end

        unless options[:command].nil?
          with_target_vms(nil, single_target: true) do |machine|
            machine.action(:ssh_run, ssh_run_command: options[:command], ssh_opts: {extra_args: ['-q']})
          end
        end
      end

      def login
        puts "Please enter credentials Subutai Console"
        puts "username: "
        username = STDIN.gets.chomp
        puts "password: "
        password = STDIN.noecho(&:gets).chomp

        uri = URI.parse(SubutaiAPI::TOKEN)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data('username' => username, 'password' => password)

        response = http.request(request)

        case response
        when Net::HTTPOK
          puts 'You successfully signed to Subutai Console'
          register(response.body)
        else
          login
        end
      end

      def register(token)
        puts "Register your peer to HUB"
        puts "Enter Hub email: "
        email = STDIN.gets.chomp
        puts "Enter Hub password: "
        password = STDIN.noecho(&:gets).chomp
        puts "Enter peer name: "
        name = STDIN.gets.chomp
        puts "1. Public"
        puts "2. Private"
        puts "Choose your peer scope (1 or 2): "
        scope = STDIN.gets.chomp.to_i

        uri = URI.parse(SubutaiAPI::REGISTER_HUB+token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({'email' => email, 'password' => password, 'peerName' => name, 'peerScope' => scope == 1 ? "Public":"Private"})

        response = https.request(request)

        case response
          when Net::HTTPOK
            puts "You peer: #{name} successfully registered to hub."
          else
            puts "Try again! "
            puts response.body
            register(token)
        end
      end
    end
  end
end