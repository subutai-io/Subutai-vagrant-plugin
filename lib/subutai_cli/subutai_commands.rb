require_relative '../subutai_cli'
require_relative 'command'
require 'net/https'
require 'io/console'
require 'fileutils'
require 'rh_controller'

module SubutaiCli
  class Commands < Vagrant.plugin('2', :command)

    def initialize(arg, env)
      super(arg, env)
    end

    # show snap logs
    def log
      ssh(SubutaiAgentCommand::LOG)
    end

    # info id
    def info(arg)
      ssh("#{SubutaiAgentCommand::INFO} #{arg}")
    end

    # update Subutai rh or management
    def update(name)
      ssh(SubutaiAgentCommand::UPDATE + " #{name}")
    end

    # register Subutai Peer to Hub
    def register(username, password)
      username, password = get_input_token if username.nil? && password.nil?
      response = SubutaiCli::Rest::SubutaiConsole.token($SUBUTAI_CONSOLE_URL, username, password)

      case response
        when Net::HTTPOK
          STDOUT.puts "Successfully you signed Subutai Console"
          hub_email, hub_password, peer_name, peer_scope = get_input_register
          response = SubutaiCli::Rest::SubutaiConsole.register(response.body, $SUBUTAI_CONSOLE_URL, hub_email, hub_password, peer_name, peer_scope)

          case response
            when Net::HTTPOK
              STDOUT.puts "You peer: \"#{peer_name}\" successfully registered to hub."
            else
              STDOUT.puts "Try again! #{response.body}\n"
              register(username, password)
          end
        else
          STDERR.puts "Try again! #{response.body}\n"
          register(nil, nil)
      end
    end

    # Add new RH to Peer
    def add(peer_path, rh_name)
      peer_path = peer_path + "/#{SubutaiCli::Subutai::RH_FOLDER_NAME}/#{rh_name}"

      # create RH folder your_peer_path/RH/rh_name
      unless File.exists?(peer_path)
        FileUtils.mkdir_p(peer_path)

        # 1. create RH
        Dir.chdir(peer_path){
          unless system(VagrantCommand::INIT + " " + $SUBUTAI_BOX_NAME)
            raise '\'vagrant init\' command failed.'
          end
        }

        # 2. up
        Dir.chdir(peer_path){
          unless system(VagrantCommand::RH_UP)
            raise '\'vagrant up\' command failed.'
          end
        }

        # 3. provision
        Dir.chdir(peer_path){
          unless system(VagrantCommand::PROVISION)
            raise '\'vagrant provision\' command failed.'
          end
        }

        # 4. TODO set Subutai Console host and fingerprint in RH agent config
        fingerprint = fingerprint($SUBUTAI_CONSOLE_URL).body
        ip = info('ipaddr')

        STDOUT.puts "Subutai Console(Peer)"
        STDOUT.puts "ip: #{ip}"
        STDOUT.puts "fingerprint: #{fingerprint}"

        # 5. Check is rh request exist in Subutai Console
        # then approve

        STDOUT.puts "Your RH path: #{peer_path}"
      end
    end

    # Show Subutai Console finger print
    def fingerprint(url)
      response = SubutaiCli::Rest::SubutaiConsole.fingerprint(url)

      case response
        when Net::HTTPOK
          STDOUT.puts response.body
        else
          STDOUT.puts "Try again! #{response.body}"
      end
    end

    # Get Subutai console credentials from input
    def get_input_token
      STDOUT.puts "\nPlease enter credentials Subutai Console:\n"
      STDOUT.puts "username: "
      username = STDIN.gets.chomp
      puts "password: "
      password = STDIN.noecho(&:gets).chomp

      [username, password]
    end

    # Get Hub credentials and peer info
    def get_input_register
      STDOUT.puts "\nRegister your peer to HUB:\n"

      # Hub email
      STDOUT.puts "Enter Hub email: "
      hub_email = STDIN.gets.chomp

      # Hub password
      STDOUT.puts "Enter Hub password: "
      hub_password = STDIN.noecho(&:gets).chomp

      # Peer name
      STDOUT.puts "Enter peer name: "
      peer_name = STDIN.gets.chomp

      # Peer scope
      STDOUT.puts "1. Public"
      STDOUT.puts "2. Private"
      STDOUT.puts "Choose your peer scope (1 or 2): "
      peer_scope = STDIN.gets.chomp.to_i

      [hub_email, hub_password, peer_name, peer_scope]
    end

    def test
      username, password = get_input_token
      response = SubutaiCli::Rest::SubutaiConsole.token($SUBUTAI_CONSOLE_URL, username, password)

      case response
        when Net::HTTPOK
          SubutaiCli::RhController.new.all(response.body)
        else
          test
      end
    end

    def ssh(command)
      with_target_vms(nil, single_target: true) do |vm|
        vm.action(:ssh_run, ssh_run_command: command, ssh_opts: {extra_args: ['-q']})
      end
    end
  end
end