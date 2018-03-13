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
      password = nil
      username = nil

      if SubutaiConfig.get(:SUBUTAI_USERNAME).nil?
        Put.warn "\nPlease enter credentials Subutai Peer Os:\n"
        Put.info "\nusername: "
        username = STDIN.gets.chomp
      else
        username = SubutaiConfig.get(:SUBUTAI_USERNAME)
      end


      if SubutaiConfig.get(:SUBUTAI_PASSWORD).nil?
        begin
          Put.info "\npassword: "
          password = STDIN.noecho(&:gets).chomp
        rescue Errno::EBADF
          Put.warn "\nStdin doesn't support echo less input. Stdin can't hide password\n"
          password = STDIN.gets
        end
      else
        password = SubutaiConfig.get(:SUBUTAI_PASSWORD)
      end

      [username, password]
    end

    # Get Bazaar credentials from input
    def get_input_login

      email = nil
      password = nil

      if SubutaiConfig.get(:BAZAAR_EMAIL).nil?
        # Bazaar email
        Put.warn "\nPlease enter credentials Bazaar:\n"
        Put.info "\nemail: "
        email = STDIN.gets.chomp
      else
        email = SubutaiConfig.get(:BAZAAR_EMAIL)
      end


      if SubutaiConfig.get(:BAZAAR_PASSWORD).nil?
        # Bazaar password
        begin
          Put.info "\nEnter Bazaar password: "
          password = STDIN.noecho(&:gets).chomp
        rescue Errno::EBADF
          Put.warn "\nStdin doesn't support echo less input. Stdin can't hide password\n"
          password = STDIN.gets
        end
      else
        password = SubutaiConfig.get(:BAZAAR_PASSWORD)
      end

      [email, password]
    end

    # Get Bazaar credentials and peer info
    def get_input_register
      Put.warn "\nRegister your peer to Bazaar:\n"

      hub_password = nil
      hub_email = nil

      if SubutaiConfig.get(:BAZAAR_EMAIL).nil?
        # Hub email
        Put.info "\nEnter Bazaar email: "
        hub_email = STDIN.gets.chomp
      else
        hub_email = SubutaiConfig.get(:BAZAAR_EMAIL)
      end


      if SubutaiConfig.get(:BAZAAR_PASSWORD).nil?
        # Hub password
        begin
          Put.info "\nEnter Bazaar password: "
          hub_password = STDIN.noecho(&:gets).chomp
        rescue Errno::EBADF
          Put.warn "\nStdin doesn't support echo less input. Stdin can't hide password\n"
          hub_password = STDIN.gets
        end
      else
        hub_password = SubutaiConfig.get(:BAZAAR_PASSWORD)
      end

      # Peer name
      peer_name = SubutaiConfig.get(:SUBUTAI_NAME)

      peer_scope = SubutaiConfig.get(:SUBUTAI_SCOPE)

      [hub_email, hub_password, peer_name, peer_scope]
    end

    def list(arg)
      ssh(base + "#{Configs::SubutaiAgentCommand::LIST} #{arg}")
    end

    def blueprint(url)
      variable = VagrantSubutai::Blueprint::VariablesController.new(0, 0, nil)

      resource = info('system')

      if variable.validate && variable.check_quota?(resource)
        mode = SubutaiConfig.get(:SUBUTAI_ENV_TYPE)

        if mode.nil?
          # check smart defaults
          fingerprint = Rest::SubutaiConsole.fingerprint(url)
          response = Rest::Bazaar.registered(fingerprint)

          case response
            when Net::HTTPOK
              # [MODE] The blueprint provisioning via Bazaar
              bazaar(url)
            when Net::HTTPNotFound
              # [MODE] blueprint provisioning via Peer Os (local)
              peer(url, resource)
            else
              Put.error response.message
              Put.error response.body
          end
        elsif mode == Configs::Blueprint::MODE::PEER
          # [MODE] blueprint provisioning via Peer Os (local)
          peer(url, resource)
        elsif mode == Configs::Blueprint::MODE::BAZAAR
          # [MODE] The blueprint provisioning via Bazaar
          bazaar(url)
        end
      end
    end

    def peer(url, resource)
      Put.success "\n--------------------------------------"
      Put.success "| Blueprint provisioning via Peer Os |"
      Put.success "--------------------------------------\n"

      username = SubutaiConfig.get(:SUBUTAI_USERNAME)
      password = SubutaiConfig.get(:SUBUTAI_PASSWORD)

      username, password = get_input_token if username.nil? && password.nil?
      response = Rest::SubutaiConsole.token(url, username, password)

      case response
        when Net::HTTPOK
          rh_id = info('id')
          peer_id = Rest::SubutaiConsole.fingerprint(url)

          env = Blueprint::EnvironmentController.new
          env.check_free_quota(resource)
          env.build(url, response.body, rh_id, peer_id, Configs::Blueprint::MODE::PEER)
        else
          Put.error "Error: #{response.body}"
          Put.warn "\n[WARNING] if you have a new PeerOS make sure you have to change the default UI console password. It’s default credentials are ‘admin’ / ‘secret’.\n"
      end
    end

    def bazaar(url)
      Put.success "\n-------------------------------------"
      Put.success "| Blueprint provisioning via Bazaar |"
      Put.success "-------------------------------------\n"
      
      email = SubutaiConfig.get(:BAZAAR_EMAIL)
      password = SubutaiConfig.get(:BAZAAR_PASSWORD)

      # Register Peer Os to Bazaar
      unless registered?(url)
        username = SubutaiConfig.get(:SUBUTAI_USERNAME)
        pwd = SubutaiConfig.get(:SUBUTAI_PASSWORD)

        username, pwd = get_input_token if username.nil? && pwd.nil?
        response = Rest::SubutaiConsole.token(url, username, pwd)

        case response
          when Net::HTTPOK
            email, password = register_by_token(response.body, url)
          else
            Put.error response.body
            Put.error response.message
        end
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
          peer_id = Rest::SubutaiConsole.fingerprint(url)

          env = Blueprint::EnvironmentController.new
          env.build(url, cookies, rh_id, peer_id, Configs::Blueprint::MODE::BAZAAR)
        else
          Put.error response.body
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