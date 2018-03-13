require_relative '../vagrant-subutai'
require 'optparse'
require 'io/console'
require 'net/https'
require 'fileutils'

module VagrantSubutai
  class Command < Vagrant.plugin('2', :command)
    attr_accessor :box
    # shows description when `vagrant list-commands` is triggered
    def self.synopsis
      'Vagrant Subutai Plugin - executes Subutai scripts in target hosts'
    end


    def execute
      cli_info

      # Gets Subutai console url and box name from Vagrantfile
      with_target_vms(nil, single_target: true) do |machine|
        @box = machine.config.vm.box
      end

      subutai_cli = Commands.new(ARGV, @env)

      case ARGV[1]
        when 'register'
          subutai_cli.register(nil, nil, check_subutai_console_url(subutai_cli))
        when 'fingerprint'
          subutai_cli.fingerprint(check_subutai_console_url(subutai_cli))
        when 'open'
          subutai_cli.open(check_subutai_console_url(subutai_cli))
        when 'blueprint'
          subutai_cli.blueprint(check_subutai_console_url(subutai_cli))
        when '-h'
          STDOUT.puts cli_info
        when '--help'
          STDOUT.puts cli_info
        else
          # All Agent CLI commands implemented here

          command = ARGV
          command.shift

          if command.empty?
            STDOUT.puts cli_info
          else
            subutai_cli.ssh("#{subutai_cli.base} #{command.join(' ')}")
          end
      end
    end

    def check_subutai_console_url(subutai_cli)
      ip = subutai_cli.info(Configs::VagrantCommand::ARG_IP_ADDR)

      if ip.nil?
        STDOUT.puts 'We can\'t detect your Subutai Console ip address!'
        exit
      end
      "https://#{ip}:#{Configs::SubutaiConsoleAPI::PORT}"
    end

    def cli_info
      commands = <<-EOF
        
Usage: vagrant subutai command [command options] [arguments...]

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
     register                - register Subutai PeerOS to Bazaar
     fingerprint             - shows fingerprint Subutai Console
     open                    - open the Subutai PeerOS in browser
     blueprint               - run blueprint provisioning

GLOBAL OPTIONS:
     -h, --help              - show help
      EOF
      commands
    end
  end
end