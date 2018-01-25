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
        cli_info

        # Gets Subutai console url and box name from Vagrantfile
        with_target_vms(nil, single_target: true) do |machine|
          $SUBUTAI_CONSOLE_URL = machine.config.subutai_console.url
          $SUBUTAI_BOX_NAME = machine.config.vm.box
        end

        subutai_cli = SubutaiCli::Commands.new(ARGV, @env)

        case ARGV[1]
          when 'register'
            check_subutai_console_url
            subutai_cli.register(nil, nil)
          when 'add'
            check_subutai_console_url
            options = {}
            opts = OptionParser.new do |opt|
              opt.banner = 'Usage: vagrant subutai add [options]'
              opt.on('-n', '--name NAME') do |name|
                options[:name] = name
              end
            end
            opts.parse!
            subutai_cli.add(Dir.pwd, options[:name])
          when 'fingerprint'
            check_subutai_console_url
            subutai_cli.fingerprint($SUBUTAI_CONSOLE_URL)
          when '-h'
            STDOUT.puts cli_info
          when '--help'
            STDOUT.puts cli_info
          else
            # All Agent CLI commands implemented here
            # Parse environment from args
            options = {}
            OptionParser.new do |opt|
              opt.on('-e', '--environment NAME', 'specify environment dev, master or sysnet') do |name|
                options[:environment] = true
                options[:environment_arg] = name
              end

              opt.on('-h', '--help', nil) do
                options[:help] = true
              end
            end.parse!

            command = ARGV
            command.shift

            unless options[:environment].nil?
              command.delete "-e"
              command.delete "--environment"
            end

            unless options[:help].nil?
              command << "-h"
            end

            if command.empty?
              STDOUT.puts cli_info
            else
              if options[:environment]
                subutai_cli.ssh("#{SubutaiAgentCommand::SUBUTAI}-#{options[:environment_arg]} #{command.join(' ')}")
              else
                subutai_cli.ssh("#{SubutaiAgentCommand::SUBUTAI} #{command.join(' ')}")
              end
            end
        end
      end

      def check_subutai_console_url
        if $SUBUTAI_CONSOLE_URL.empty?
          STDOUT.puts "Please add this to Vagrantfile => config.subutai_console.url = \"https://YOUR_LOCAL_PEER_IP:YOUR_LOCAL_PEER_PORT\""
          exit
        end
      end

      def cli_info
        commands = <<-EOF
          
Usage: vagrant subutai [global options] command [command options] [arguments...]

COMMANDS:
       attach                  - attach to Subutai container
       backup                  - backup Subutai container
       batch                   - batch commands execution
       checkpoint              - checkpoint/restore in user space
       clone                   - clone Subutai container
       cleanup                 - clean Subutai environment
       config                  - edit container config
       daemon                  - start Subutai agent
       demote                  - demote Subutai container
       destroy                 - destroy Subutai container
       export                  - export Subutai container
       import                  - import Subutai template
       info                    - information about host system
       hostname                - Set hostname of container or host
       list                    - list Subutai container
       log                     - print application logs
       map                     - Subutai port mapping
       metrics                 - list Subutai container
       migrate                 - migrate Subutai container
       p2p                     - P2P network operations
       promote                 - promote Subutai container
       proxy                   - Subutai reverse proxy
       quota                   - set quotas for Subutai container
       rename                  - rename Subutai container
       restore                 - restore Subutai container
       stats                   - statistics from host
       start                   - start Subutai container
       stop                    - stop Subutai container
       tunnel                  - SSH tunnel management
       update                  - update Subutai management, container or Resource host
       vxlan                   - VXLAN tunnels operation
       register                - register Subutai Peer to Hub
       add                     - add new RH to Subutai Peer
       fingerprint             - shows fingerprint Subutai Console

GLOBAL OPTIONS:
       -e, --environment NAME  - specify environment dev, master or sysnet
       -h, --help              - show help
        EOF
        commands
      end
    end
  end
end