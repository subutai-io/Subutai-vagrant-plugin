require_relative '../subutai_cli'
require_relative 'command'
require 'net/https'
require 'io/console'
require 'fileutils'

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
    def info
      ssh(SubutaiAgentCommand::INFO_ID)
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

    def add(peer_path, rh_name)
      peer_path = peer_path + "/#{SubutaiCli::Subutai::RH_FOLDER_NAME}/#{rh_name}"

      # create folder your_peer+path/RH/rh_name
      unless File.exists?(peer_path)
        FileUtils.mkdir_p(peer_path)
      end

      # 1. create RH
      Dir.chdir(peer_path){
        %x[#{VagrantCommand::INIT}]
      }

      # 2. up
      Dir.chdir(peer_path){
        %x[#{VagrantCommand::RH_UP}]
      }

      id = info
      puts id

      STDOUT.puts "Your RH path: #{peer_path}"
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

    def ssh(command)
      with_target_vms(nil, single_target: true) do |vm|
        vm.action(:ssh_run, ssh_run_command: command, ssh_opts: {extra_args: ['-q']})
      end
    end
  end
end