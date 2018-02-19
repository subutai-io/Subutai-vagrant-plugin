require_relative '../vagrant-subutai'
require 'net/https'
require 'io/console'
require 'fileutils'

module VagrantSubutai
  class Commands < Vagrant.plugin('2', :command)

    def initialize(arg, env)
      super(arg, env)
    end

    # show snap logs
    def log
      ssh(base + Configs::SubutaiAgentCommand::LOG)
    end

    def base
      env = SubutaiConfig.get(:SUBUTAI_ENV)

      if env.nil?
        Configs::SubutaiAgentCommand::BASE
      else
        if env.to_s == 'prod'
          Configs::SubutaiAgentCommand::BASE
        else
          "sudo /snap/bin/subutai-#{env.to_s}"
        end
      end
    end

    # info id
    def info(arg)
      with_target_vms(nil, single_target: true) do |vm|
        vm.communicate.sudo("#{base} #{Configs::SubutaiAgentCommand::INFO} #{arg}") do |type, data|
          if type == :stdout
            result = data.split(/[\r\n]+/)
            return result.first
          end
        end
      end
    end

    # update Subutai rh or management
    def update(name)
      ssh(base + Configs::SubutaiAgentCommand::UPDATE + " #{name}")
    end

    # register Subutai Peer to Hub
    def register(username, password, url)
      username, password = get_input_token if username.nil? && password.nil?
      response = Rest::SubutaiConsole.token(url, username, password)

      case response
        when Net::HTTPOK
          STDOUT.puts 'Successfully you signed Subutai Console'
          hub_email, hub_password, peer_name, peer_scope = get_input_register
          response = Rest::SubutaiConsole.register(response.body, url, hub_email, hub_password, peer_name, peer_scope)

          case response
            when Net::HTTPOK
              STDOUT.puts "Body: #{response.body}"
              STDOUT.puts "You peer: \"#{peer_name}\" successfully registered to hub."
              SubutaiConfig.put(:_REGISTERED, true, true)
            else
              STDOUT.puts "Try again! #{response.body}\n"
              register(username, password, url)
          end
        else
          STDERR.puts "Try again! #{response.body}\n"
          register(nil, nil, url)
      end
    end

    # Show Subutai Console finger print
    def fingerprint(url)
      peer_id = Rest::SubutaiConsole.fingerprint(url)
      STDOUT.puts peer_id
    end

    # Get Subutai console credentials from input
    def get_input_token
      STDOUT.puts '\nPlease enter credentials Subutai Console:\n'
      STDOUT.puts 'username: '
      username = STDIN.gets.chomp
      puts 'password: '
      password = STDIN.noecho(&:gets).chomp

      [username, password]
    end

    # Get Hub credentials and peer info
    def get_input_register
      STDOUT.puts '\nRegister your peer to HUB:\n'

      # Hub email
      STDOUT.puts 'Enter Hub email: '
      hub_email = STDIN.gets.chomp

      # Hub password
      STDOUT.puts 'Enter Hub password: '
      hub_password = STDIN.noecho(&:gets).chomp

      # Peer name
      STDOUT.puts 'Enter peer name: '
      peer_name = STDIN.gets.chomp

      # Peer scope
      STDOUT.puts '1. Public'
      STDOUT.puts '2. Private'
      STDOUT.puts 'Choose your peer scope (1 or 2): '
      peer_scope = STDIN.gets.chomp.to_i

      [hub_email, hub_password, peer_name, peer_scope]
    end

    def list(arg)
      ssh(base + "#{Configs::SubutaiAgentCommand::LIST} #{arg}")
    end

    def blueprint(url)
      rh_id = info('id')
      peer_id = Rest::SubutaiConsole.fingerprint(url)

      env = Blueprint::EnvironmentController.new
      STDOUT.puts env.build(rh_id, peer_id)
    end

    def ssh(command)
      with_target_vms(nil, single_target: true) do |vm|
        vm.action(:ssh_run, ssh_run_command: command, ssh_opts: {extra_args: ['-q']})
      end
    end
  end
end