require 'vagrant'

module SubutaiCli
  module Subutai
    class Command < Vagrant.plugin('2', :command)
      # show description when `vagrant list-comands` is triggered
      def self.synopsis
        "Vagrant Subutai CLI - executes Subutai scripts in target hosts"
      end

      def execute
        command, command_args = parse_args 
        command && command_args or return nil
        command = $subutai + command
        with_target_vms(nil, single_target:true) do |vm|
          command = command + " " + command_args.join(' ') if command_args.any?
          if vm.state.id != :running
            env.ui.info("#{vm.name} is not running.")
          end
          puts "#{command}"
          vm.action(:ssh_run, ssh_run_command: command)
        end
      end

      private
      def parse_args
        opts = OptionParser.new do |opt|
          opt.banner = "
          Usage: vagrant subutai <command> [options]
          Available commands:
          clone           - clones an instance container from a template
          config          - adds or deletes a config path on a container
          demote          - demotes a template back to an instance container
          destroy         - destroys a template or instance container
          export          - export a template
          import          - import a template
          list            - lists templates and instance containers
          master_create   - creates a new master from scratch
          master_destroy  - destroys the master template
          master_export   - exports the master template
          master_import   - imports master template
          promote         - promotes an instance container into a template
          register        - registers the template with the site registry
          rename          - renames an instance container
          setup           - setups up the host"

          opt.separator ''

          opt.on('-h', '--help', 'Print help') do
            safe_puts(opt.help)
          end

          argv = split_main_and_subcommand(@argv.dup)

          exec_args, command, command_args = argv[0], argv[1], argv[2]

          #if no args supplied print 'help'
          if !command || exec_args.any? { |a| a == '-h' || a == '--help' }
            safe_puts(opt.help)
            return nil
          end

          return command, command_args
        end
      end
    end
  end
end






