require_relative '../subutai_cli'
require 'optparse'
require 'io/console'
require 'net/https'
require_relative 'subutai_commands'
require 'fileutils'

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

          opt.on('-a', '--add NAME', 'add new RH to Subutai Peer') do |name|
            options[:rh] = true
            options[:rh_arg] = name
          end

          opt.on('-i', '--info NAME', 'information about host system: id, ipaddr') do |id|
            options[:info] = true
            options[:info_arg] = id
          end

          opt.on('-f', '--fingerprint', 'shows fingerprint Subutai Console') do
            options[:fingerprint] = true
          end

          opt.on('-t', '--test', 'Json parse test') do
            options[:test] = true
          end
        end

        # Gets Subutai console url and box name from Vagrantfile
        with_target_vms(nil, single_target: true) do |machine|
          $SUBUTAI_CONSOLE_URL = machine.config.subutai_console.url
          $SUBUTAI_BOX_NAME = machine.config.vm.box
        end

        argv = parse_options(opts)
        return if !argv

        subutai_cli = SubutaiCli::Commands.new(ARGV, @env)
        if options[:log]
          subutai_cli.log
        elsif options[:update]
          subutai_cli.update(options[:update_arg])
        elsif options[:register]
          check_subutai_console_url

          subutai_cli.register(nil, nil)
        elsif options[:rh]
          subutai_cli.add(Dir.pwd, options[:rh_arg])
        elsif options[:info]
          subutai_cli.info(options[:info_arg])
        elsif options[:fingerprint]
          check_subutai_console_url

          subutai_cli.fingerprint($SUBUTAI_CONSOLE_URL)
        else
          STDOUT.puts "For help on any individual command run `vagrant subutai -h`"
        end
      end

      def check_subutai_console_url
        if $SUBUTAI_CONSOLE_URL.empty?
          STDOUT.puts "Please add this to Vagrantfile => config.subutai_console.url = \"https://YOUR_LOCAL_PEER_IP:YOUR_LOCAL_PEER_PORT\""
          exit
        end
      end
    end
  end
end