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
        opts = OptionParser.new do |opt|
          opt.banner = 
          "Usage: vagrant subutai --<command> [options]
           Available commands: 
          "
          opt.separator ""

          opt.on("-l", "--log", "show logs snap") do
            options[:command] = SubutaiCommands::LOG
          end

          opt.on("-u", "--update", "update Subutai Resource host") do
            options[:command] = SubutaiCommands::UPDATE_RH 
          end
        end

        argv = parse_options(opts)
        return if !argv

        unless options[:command].nil?
          with_target_vms(nil, single_target: true) do |machine|
            machine.action(:ssh_run, ssh_run_command: options[:command], ssh_opts: {extra_args: ['-q']})
          end
        end
      end
    end
  end
end






