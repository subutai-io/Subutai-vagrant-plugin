require 'vagrant'

module SubutaiCli
  module Subutai
    class Command < Vagrant.plugin('2', :command)
      $subutai = "subutai "
      # show description when `vagrant list-comands` is triggered
      def self.synopsis
        "Vagrant Subutai CLI - executes Subutai scripts in target hosts"
      end

      def execute
        machine = @env.machine(:default, :virtualbox)
        puts machine.state.id
        puts @argv 

        with_target_vms(nil, single_target: true) do |machine|
          puts machine.name
          puts machine.state.id
          puts "Command: #{@argv}"

          puts 'trying to run command'
          machine.action(:ssh_run, ssh_run_command: 'sudo /snap/bin/subutai log', ssh_opts: {extra_args: ['-q']})
        end
      end
    end
  end
end






