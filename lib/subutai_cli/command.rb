require_relative '../subutai_cli'
require 'optparse'
require 'io/console'
require 'net/https'
require_relative 'subutai_commands'

module SubutaiCli
  module Subutai
    class Command < Vagrant.plugin('2', :command)
      # shows description when `vagrant list-commands` is triggered
      def self.synopsis
        'Vagrant Subutai CLI - executes Subutai scripts in target hosts'
      end

      def execute
        options = {}
        opts = OptionParser.new do |opt|
          opt.banner = 'Usage: vagrant subutai --<command> [options]'
          opt.separator ''

          opt.on('-l', '--log', 'show snap logs') do
            options[:log] = true
          end

          opt.on('-u', '--update NAME', 'update Subutai rh or management') do |name|
            options[:update] = true
            options[:update_arg] = name
          end

          opt.on('-r', '--register', 'register Subutai Peer to Hub') do
            options[:register] = true
          end
        end

        # Gets Subutai console url from Vagrantfile
        with_target_vms(nil, single_target: true) do |machine|
          $SUBUTAI_CONSOLE_URL = machine.config.subutai_console.url
        end

        argv = parse_options(opts)
        return if !argv

        subutai_cli = SubutaiCli::Commands.new(ARGV, @env)
        if options[:log]
          subutai_cli.log
        elsif options[:update]
          subutai_cli.update(options[:update_arg])
        elsif options[:register]
          if $SUBUTAI_CONSOLE_URL.empty?
            puts "Please add this to Vagrantfile => config.subutai_console.url = \"https://YOUR_LOCAL_PEER_IP:YOUR_LOCAL_PEER_PORT\""
            exit
          end

          gets_input_register(subutai_cli, $SUBUTAI_CONSOLE_URL)
        else
          puts "For help on any individual command run `vagrant subutai -h`"
        end
      end

      # Get input data from console for register peer to hub
      def gets_input_register(obj, url)
        STDOUT.puts "\nPlease enter credentials Subutai Console:\n"
        STDOUT.puts "username: "
        username = STDIN.gets.chomp
        puts "password: "
        STDOUT.password = STDIN.noecho(&:gets).chomp

        # (url, username, password, hub_email, hub_password, peer_name, peer_scope)
        response = obj.register(url, username, password, nil, nil, nil, nil)

        if response.code == Net::HTTPOK
          STDOUT.puts "\nRegister your peer to HUB:\n"
          STDOUT.puts "Enter Hub email: "
          hub_email = STDIN.gets.chomp
          STDOUT.puts "Enter Hub password: "
          hub_password = STDIN.noecho(&:gets).chomp
          STDOUT.puts "Enter peer name: "
          peer_name = STDIN.gets.chomp
          STDOUT.puts "1. Public"
          STDOUT.puts "2. Private"
          STDOUT.puts "Choose your peer scope (1 or 2): "
          peer_scope = STDIN.gets.chomp.to_i

          response = obj.register(url, username, password, hub_email, hub_password, peer_name, peer_scope == 1 ? "Public" : "Private")

          if response.code == Net::HTTPOK
            STDOUT.puts "\nYou peer: \"#{name}\" successfully registered to hub.\n"
          else 
            gets_input_register(obj, url)
          end
        else
          gets_input_register(obj, url)
        end  
      end
    end
  end
end