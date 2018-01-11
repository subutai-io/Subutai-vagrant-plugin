require 'vagrant'
require 'optparse'
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
        opts = OptionParser.new do |opts|
          opts.banner = 
          "Usage: vagrant subutai --<command> [options]
           Available commands:
          "
          opts.separator ""

          opts.on("-l", "--log", "show logs snap") do
            options[:log] = true
          end

          opts.on("-u", "--update", "update Subutai Resource host") do
            options[:update] = true 
          end
        end

        argv = parse_options(opts)
        return if !argv

        if options[:update]
          with_target_vms(nil, single_target: true) do |machine|
            machine.action(:ssh_run, ssh_run_command: SubutaiCommands::UPDATE_RH, ssh_opts: {extra_args: ['-q']})
          end
        end

        if options[:log]
          with_target_vms(nil, single_target: true) do |machine|
            machine.action(:ssh_run, ssh_run_command: SubutaiCommands::LOG, ssh_opts: {extra_args: ['-q']})
          end
        end
      end
    end
  end
end






