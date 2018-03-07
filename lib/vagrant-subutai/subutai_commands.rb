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

    # checks The Peer Os registered or not registered to Bazaar
    def registered?(url)
      fingerprint = Rest::SubutaiConsole.fingerprint(url)
      response = Rest::Bazaar.registered(fingerprint)

      case response
        when Net::HTTPOK
          return true
        when Net::HTTPNotFound
          return false
        else
          Put.error response.body
          Put.error response.message
          exit
      end
    end

    # register Subutai Peer Os to Bazaar by username and password
    def register(username, password, url)
      if registered?(url)
        Put.warn "\nThe Peer Os already registered to Bazaar.\n"
      else
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
    end

    # register Subutai Peer Os to Bazaar by token
    def register_by_token(token, url)
      hub_email, hub_password, peer_name, peer_scope = get_input_register
      peer_scope = peer_scope == 1 ? 'Public':'Private'
      response = Rest::SubutaiConsole.register(token, url, hub_email, hub_password, peer_name, peer_scope)

      case response
        when Net::HTTPOK
          Put.success response.body
          Put.success "\"#{peer_name}\" successfully registered to Bazaar."
          [hub_email, hub_password]
        else
          Put.error "Error: #{response.body}\n"
          register_by_token(token, url)
      end
    end

    # Show Subutai Console finger print
    def fingerprint(url)
      peer_id = Rest::SubutaiConsole.fingerprint(url)
      Put.info peer_id
    end

    # Get Subutai Peer Os credentials from input
    def get_input_token
      Put.warn "\nPlease enter credentials Subutai Peer Os:\n"
      Put.info "\nusername: "
      username = STDIN.gets.chomp
      Put.info "\npassword: "
      password = STDIN.noecho(&:gets).chomp

      [username, password]
    end

    # Get Bazaar credentials from input
    def get_input_login
      Put.warn "\nPlease enter credentials Bazaar:\n"
      Put.info "\nemail: "
      email = STDIN.gets.chomp
      Put.info "\npassword: "
      password = STDIN.noecho(&:gets).chomp

      [email, password]
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
      variable = VagrantSubutai::Blueprint::VariablesController.new(0, 0, nil)

      if variable.validate
        mode = SubutaiConfig.get(:SUBUTAI_ENV_TYPE)

        if mode.nil?
          # check smart defaults
          fingerprint = Rest::SubutaiConsole.fingerprint(url)
          response = Rest::Bazaar.registered(fingerprint)

          case response
            when Net::HTTPOK
              # [MODE] The blueprint provisioning via Bazaar
              bazaar(url, variable.has_ansible?)
            when Net::HTTPNotFound
              # [MODE] blueprint provisioning via Peer Os (local)
              peer(url)
            else
              Put.error response.message
              Put.error response.body
          end
        elsif mode == Configs::Blueprint::MODE::PEER
          # [MODE] blueprint provisioning via Peer Os (local)
          peer(url)
        elsif mode == Configs::Blueprint::MODE::BAZAAR
          # [MODE] The blueprint provisioning via Bazaar
          bazaar(url, variable.has_ansible?)
        end
      end
    end

    def peer(url)
      Put.info "\nBlueprint provisioning via Peer Os\n"
      username, password = get_input_token if username.nil? && password.nil?
      response = Rest::SubutaiConsole.token(url, username, password)

      case response
        when Net::HTTPOK
          rh_id = info('id')
          resource = info('system')
          peer_id = Rest::SubutaiConsole.fingerprint(url)

          env = Blueprint::EnvironmentController.new
          env.check_free_quota(resource)
          env.build(url, response.body, rh_id, peer_id, Configs::Blueprint::MODE::PEER)
        else
          Put.error "Error: #{response.body}"
      end
    end

    def bazaar(url, has_ansible)
      Put.info "\nBlueprint provisioning via Bazaar\n"

      if has_ansible
        username, password = get_input_token if username.nil? && password.nil?
        response = Rest::SubutaiConsole.token(url, username, password)

        case response
          when Net::HTTPOK
            token = response.body
            email = nil
            password = nil

            # Register Peer Os to Bazaar
            unless registered?(url)
              email, password = register_by_token(token, url)
            end

            email, password = get_input_login if email.nil? && password.nil?
            response = Rest::Bazaar.login(email, password)

            case response
              when Net::HTTPOK
                all_cookies = response.get_fields('set-cookie')
                cookies_array = Array.new
                all_cookies.each { | cookie |
                  cookies_array.push(cookie.split('; ')[0])
                }
                cookies = cookies_array.join('; ')

                rh_id = info('id')
                resource = info('system')
                peer_id = Rest::SubutaiConsole.fingerprint(url)

                env = Blueprint::EnvironmentController.new
                env.peer_os_token = token
                env.check_free_quota(resource)
                env.build(url, cookies, rh_id, peer_id, Configs::Blueprint::MODE::BAZAAR)
              else
                Put.error response.body
            end
          else
            Put.error "Error: #{response.body}"
        end
      else
        # Register Peer Os to Bazaar
        unless registered?(url)
          email, password = register(nil, nil, url)
        end

        email, password = get_input_login if email.nil? && password.nil?
        response = Rest::Bazaar.login(email, password)

        case response
          when Net::HTTPOK
            all_cookies = response.get_fields('set-cookie')
            cookies_array = Array.new
            all_cookies.each { | cookie |
              cookies_array.push(cookie.split('; ')[0])
            }
            cookies = cookies_array.join('; ')

            rh_id = info('id')
            resource = info('system')
            peer_id = Rest::SubutaiConsole.fingerprint(url)

            env = Blueprint::EnvironmentController.new
            env.peer_os_token = token
            env.check_free_quota(resource)
            env.build(url, cookies, rh_id, peer_id, Configs::Blueprint::MODE::BAZAAR)
          else
            Put.error response.body
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