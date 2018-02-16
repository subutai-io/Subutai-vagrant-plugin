require_relative '../vagrant-subutai'
require 'optparse'
require 'io/console'
require 'net/https'
require_relative 'subutai_commands'
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
          options = {}
          OptionParser.new do |opt|
            opt.banner = 'Usage: vagrant subutai register [options]'

            opt.on('-f', '--force', 'Register Subutai to hub force') do
              options[:force] = true
            end
          end.parse!

          if options[:force]
            subutai_cli.register(nil, nil, check_subutai_console_url(subutai_cli))
          elsif SubutaiConfig.get(:_REGISTERED)
            STDOUT.puts "Already registered peer to hub!"
          else
            subutai_cli.register(nil, nil, check_subutai_console_url(subutai_cli))
          end
        when 'fingerprint'
          subutai_cli.fingerprint(check_subutai_console_url(subutai_cli))
        when 'disk'
          OptionParser.new do |opt|
            opt.banner = 'Usage: vagrant subutai disk [options]'

            opt.on('-s', '--size NUMBER', 'set your disk size') do |num|
              disk = num.to_i

              generated_disk = SubutaiConfig.get(:_DISK_SIZE)

              if generated_disk.nil?
                grow_by = disk - 100 # default Subutai disk is 100 gigabytes
              else
                grow_by = disk - (generated_disk.to_i + 100) # HERE Applied math BEDMAS rule
              end

              if grow_by > 0
                SubutaiConfig.put(:DISK_SIZE, num, true)
                STDOUT.puts "    \e[33mWarning the disk change cannot be applied until a restart of the VM.\e[0m"
              else
                STDOUT.puts "    \e[33mWarning the operation will be ignored because it shrink operations are not supported.\e[0m"
              end
            end

            opt.on('-i', '--info', 'shows Subutai disk capacity') do
              disk = SubutaiConfig.get(:DISK_SIZE)

              if disk.nil?
                STDOUT.puts "    \e[32mSubutai disk capacity is 100 gb.\e[0m"
              else
                STDOUT.puts "    \e[32mSubutai disk capacity is #{disk} gb.\e[0m"
              end
            end
          end.parse!
        when 'blueprint'
          subutai_cli.blueprint
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
      ip = subutai_cli.info(VagrantCommand::ARG_IP_ADDR)

      if ip.nil?
        STDOUT.puts "We can't detect your Subutai Console ip address!"
        exit
      end
      "https://#{ip}:#{SubutaiConsoleAPI::PORT}"
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
     register                - register Subutai Peer to Hub
     fingerprint             - shows fingerprint Subutai Console
     disk                    - manage Subutai disk
     blueprint               - build Blueprint

GLOBAL OPTIONS:
     -h, --help              - show help
      EOF
      commands
    end
  end
end