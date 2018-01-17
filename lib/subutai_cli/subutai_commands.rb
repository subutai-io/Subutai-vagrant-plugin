require_relative '../subutai_cli'
require_relative 'command'
require 'https/net'

module SubutaiCli
  class Commands < Vagrant.plugin('2', :command)

    def initialize(arg, env)
      super(arg, env)
    end

    # show snap logs
    def log
      ssh(SubutaiAgentCommand::LOG)
    end

    # update Subutai rh or management
    def update(name)
      ssh(SubutaiAgentCommand::UPDATE + " #{name}")
    end

    # register Subutai Peer to Hub
    def register(url, username, password, hub_email, hub_password, peer_name, peer_scope)
      response = SubutaiCli::Rest::SubutaiConsole.token(url, username, password)

      if response.code == Net::HTTPOK
        response = SubutaiCli::Rest::SubutaiConsole.register(url, hub_email, hub_password, peer_name, peer_scope)

        if response.code == Net::HTTPOK
          STDOUT.puts response.body
          return response
        else
          STDOUT.puts response.body
          return response
        end
      else
        STDOUT.puts response.body
        return response
      end
    end

    def ssh(command)
      with_target_vms(nil, single_target: true) do |vm|
        vm.action(:ssh_run, ssh_run_command: command, ssh_opts: {extra_args: ['-q']})
      end
    end
  end
end