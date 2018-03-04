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
          hub_email, hub_password, peer_name, peer_scope = get_input_register
          peer_scope = peer_scope == 1 ? 'Public':'Private'
          response = Rest::SubutaiConsole.register(response.body, url, hub_email, hub_password, peer_name, peer_scope)

          case response
            when Net::HTTPOK
              Put.success response.body
              Put.success "\"#{peer_name}\" successfully registered to Bazaar."
            else
              Put.error "Error: #{response.body}\n"
              register(username, password, url)
          end
        else
          Put.error "Error: #{response.body}\n"
          register(nil, nil, url)
      end
    end

    # Show Subutai Console finger print
    def fingerprint(url)
      peer_id = Rest::SubutaiConsole.fingerprint(url)
      Put.info peer_id
    end

    # Get Subutai console credentials from input
    def get_input_token
      Put.warn "\nPlease enter credentials Subutai Peer Os:\n"
      Put.info "\nusername: "
      username = STDIN.gets.chomp
      Put.info "\npassword: "
      password = STDIN.noecho(&:gets).chomp

      [username, password]
    end

    # Get Hub credentials and peer info
    def get_input_register
      Put.warn "\nRegister your peer to Bazaar:\n"

      # Hub email
      Put.info "\nEnter Bazaar email: "
      hub_email = STDIN.gets.chomp

      # Hub password
      Put.info "\nEnter Bazaar password: "
      hub_password = STDIN.noecho(&:gets).chomp

      # Peer name
      Put.info "\nEnter Peer Os name: "
      peer_name = STDIN.gets.chomp

      # Peer scope
      Put.info "\n1. Public"
      Put.info "2. Private"
      Put.info "\nChoose your Peer Os scope (1 or 2): "
      peer_scope = STDIN.gets.chomp.to_i

      [hub_email, hub_password, peer_name, peer_scope]
    end

    def list(arg)
      ssh(base + "#{Configs::SubutaiAgentCommand::LIST} #{arg}")
    end

    def blueprint(url)
      variable = VagrantSubutai::Blueprint::VariablesController.new(0, 0)

      if variable.validate
        username, password = get_input_token if username.nil? && password.nil?
        response = Rest::SubutaiConsole.token(url, username, password)

        case response
          when Net::HTTPOK
            rh_id = info('id')
            peer_id = Rest::SubutaiConsole.fingerprint(url)
            response = VagrantSubutai::Rest::SubutaiConsole.test1(url, response.body, 'edf7dc66-d712-4631-abb8-b7c8d30d5635', "check.kg")
            Put.info response.body
            Put.info response.code
            Put.info response.message

            #env = Blueprint::EnvironmentController.new
            #env.build(url, response.body, rh_id, peer_id)
          else
            Put.error "Error: #{response.body}"
        end
      end
    end

    # opens browser
    def open(link)
      if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
        system "start #{link}"
      elsif RbConfig::CONFIG['host_os'] =~ /darwin/
        system "open #{link}"
      elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
        system "xdg-open #{link}"
      end
    end

    def ssh(command)
      with_target_vms(nil, single_target: true) do |vm|
        vm.action(:ssh_run, ssh_run_command: command, ssh_opts: {extra_args: ['-q']})
      end
    end
  end
end