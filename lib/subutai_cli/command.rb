require 'vagrant'
require 'optparse'
require 'net/https'
require 'io/console'
require 'uri'
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
          opt.banner = "Usage: vagrant subutai --<command> [options]"
          opt.separator ""

          opt.on("-l", "--log", "show snap logs") do
            options[:command] = SubutaiCommands::LOG
          end

          opt.on("-u", "--update NAME", "update Subutai rh or management") do |name|
            options[:command] = SubutaiCommands::UPDATE + " " + name
          end

          opt.on("-r", "--register", "register Subutai Peer to Hub") do
            options[:register] = true
          end

          opt.on("-b", "--build TEMPLATE_NAME", "build custom Subutai template") do |name|
            options[:build] = true
            @template_name = name
          end
        end

        @subutai_console_url = ""
        with_target_vms(nil, single_target: true) do |machine|
          @subutai_console_url = machine.config.subutai_console.url
          puts "Peer URL: #{@subutai_console_url}"
        end

        argv = parse_options(opts)
        return if !argv

        if options[:register]
          login(@subutai_console_url)
        end

        if options[:build]
          build(@template_name)
        end

        unless options[:command].nil?
          with_target_vms(nil, single_target: true) do |machine|
            machine.action(:ssh_run, ssh_run_command: options[:command], ssh_opts: {extra_args: ['-q']})
          end
        end
      end

      def login(url)
        if url.empty?
          puts "Please add this to Vagrantfile => config.subutai_console.url = \"https://YOUR_LOCAL_PEER_IP:YOUR_LOCAL_PEER_PORT\""
          exit
        end

        puts ""
        puts "Please enter credentials Subutai Console"
        puts ""
        puts "username: "
        username = STDIN.gets.chomp
        puts "password: "
        password = STDIN.noecho(&:gets).chomp

        uri = URI.parse(url+SubutaiAPI::TOKEN)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data('username' => username, 'password' => password)

        response = http.request(request)

        case response
        when Net::HTTPOK
          puts 'You successfully signed to Subutai Console'
          register(response.body, url)
        else
          login(url)
        end
      end

      def register(token, url)
        puts ""
        puts "Register your peer to HUB"
        puts ""
        puts "Enter Hub email: "
        email = STDIN.gets.chomp
        puts "Enter Hub password: "
        password = STDIN.noecho(&:gets).chomp
        puts "Enter peer name: "
        name = STDIN.gets.chomp
        puts "1. Public"
        puts "2. Private"
        puts "Choose your peer scope (1 or 2): "
        scope = STDIN.gets.chomp.to_i

        uri = URI.parse(url+SubutaiAPI::REGISTER_HUB+token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({'email' => email, 'password' => password, 'peerName' => name, 'peerScope' => scope == 1 ? "Public":"Private"})

        response = https.request(request)

        case response
          when Net::HTTPOK
            puts "You peer: #{name} successfully registered to hub."
          else
            puts "Try again!"
            puts response.body
            login(url)
        end
      end

      # Build Subutai Template
      def build(name)
        # Preparing Environment
        # Imported ubuntu16 image to the system:
        with_target_vms(nil, single_target: true) do |vm|
          vm.action(:ssh_run, ssh_run_command: SubutaiCommands::TEMPLATE_IMPORT, ssh_opts: {extra_args: ['-q']})
        end

        # Preparing container
        # clone ubuntu16 template to container with required name
        with_target_vms(nil, single_target: true) do |vm|
          vm.action(:ssh_run, ssh_run_command: SubutaiCommands::TEMPLATE_CLONE + " " + name, ssh_opts: {extra_args: ['-q']})
        end

        # Attach container to execute installation commands inside container
        with_target_vms(nil, single_target: false) do |vm|
          vm.action(:ssh_run, ssh_run_command: SubutaiCommands::TEMPLATE_ATTACH + " " + name, ssh_opts: {extra_args: ['-q']})
        end

        with_target_vms(nil, single_target: true) do |vm|
          vm.action(:ssh_run, ssh_run_command: SubutaiCommands::TEMPLATE_EXPORT + " " + name, ssh_opts: {extra_args: ['-q']})
        end
      end
    end
  end
end