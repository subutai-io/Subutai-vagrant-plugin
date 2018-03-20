require_relative '../../vagrant-subutai'
require 'json'

module VagrantSubutai
  module Blueprint
    class AnsibleController
      attr_accessor :ansible,      # ansible model
                    :environment,  # environment model
                    :url,          # Subutai Console url
                    :token         # Subutai Console token

      def initialize(ansible, environment, url, token)
        @ansible = ansible
        @environment = environment
        @url = url
        @token = token
      end

      # Adds template hosts to ansible configuration
      # /etc/ansible/hosts
      def hosts
        Put.warn "\nStarted configuring ansible hosts.......\n"
        @ansible.groups.each do |group|
          Put.info "Adding group [#{group['name']}]"

          response = Rest::SubutaiConsole.command("echo [#{group['name']}] >> /etc/ansible/hosts", @environment.ansible_host_id, "/root","1000", @url, @token)
          status(response)

          group['hostnames'].each do |hostname|
            container = find(hostname)
            Put.info "Adding hosts #{container.containerName} to group [#{group['name']}]"

            if group.key?('python-interpreter')
              response = Rest::SubutaiConsole.command("echo \"#{container.containerName} ansible_user=root template=#{hostname} ansible_ssh_host=#{container.ip} ansible_python_interpreter=#{group['python-interpreter']}\" >> /etc/ansible/hosts",
                                                      @environment.ansible_host_id,
                                                      "/root",
                                                      "360000",
                                                      @url, @token)
              status(response)
            else
              response = Rest::SubutaiConsole.command("echo \"#{container.containerName} ansible_user=root template=#{hostname} ansible_ssh_host=#{container.ip}\" >> /etc/ansible/hosts",
                                                      @environment.ansible_host_id,
                                                      "/root","360000",
                                                      @url, @token)
              status(response)
            end
          end
        end
      end

      # Downloads ansible source
      def download
        Put.info "\nStarted downloading ansible source...."
        response = Rest::SubutaiConsole.command_async("bash /root/get_unzip.sh #{@ansible.source_url}",
                                                      @environment.ansible_host_id,
                                                      "/root","360000",
                                                      @url, @token)

        case response
          when Net::HTTPOK
            json = JSON.parse(response.body)
            track(json['id'])
          when Net::HTTPAccepted
            json = JSON.parse(response.body)
            track(json['id'])
          else
            Put.error response.body
            Put.error response.message
        end
      end

      # polls command log
      #
      # {
      #    "exitCode": 127,
      #    "stdOut": "",
      #    "stdErr": "bash: /root/get_unzip.sh: No such file or directory\n",
      #    "status": "FAILED"
      # }
      #
      def track(command_id)
        response = Rest::SubutaiConsole.command_log(@url, @token, command_id)

        case response
          when Net::HTTPOK
            @log = JSON.parse response.body
            @tmp = nil

            until @log['status'] == Configs::CommandState::FAILED    ||
                  @log['status'] == Configs::CommandState::KILLED    ||
                  @log['status'] == Configs::CommandState::TIMEOUT   ||
                  @log['status'] == Configs::CommandState::SUCCEEDED

              res = Rest::SubutaiConsole.command_log(@url, @token, command_id)

              begin
                @log = JSON.parse res.body

                if @tmp.nil?
                  Put.info @log['stdOut']
                else
                  msg = @log['stdOut']

                  if @tmp.length < msg.length
                    msg = msg[(@tmp.length)..(msg.length-1)]
                    Put.info msg
                  end
                end

                @tmp = @log['stdOut']
              rescue JSON::ParserError => e
                Put.error e
              end

              sleep 5 # sleep 5 seconds
            end

            if @log['status'] == Configs::CommandState::SUCCEEDED
              Put.success @log['status']
            else
              Put.error @log['status']
              Put.error @log['stdErr']
            end
          else
            Put.error response.body
            Put.error response.message
        end
      end

      # Runs ansible playbook
      def run
        Put.info "\nStarted running ansible playbook may be take too long time please wait......."
        if @ansible.extra_vars.empty?
          response = Rest::SubutaiConsole.command_async("cd /root/*master/;ansible-playbook #{@ansible.ansible_playbook}", @environment.ansible_host_id, "/root","360000", @url, @token)

          case response
            when Net::HTTPOK
              json = JSON.parse(response.body)
              track(json['id'])
            when Net::HTTPAccepted
              json = JSON.parse(response.body)
              track(json['id'])
            else
              Put.error response.body
              Put.error response.message
          end
        else
          extra_vars = {}
          @ansible.extra_vars.each do |extra_var|
            extra_var.map {|k, v| extra_vars[k] = v }
          end
          response = Rest::SubutaiConsole.command_async("cd /root/*master;ansible-playbook #{@ansible.ansible_playbook} --extra-vars '#{extra_vars.to_json}'", @environment.ansible_host_id, "/root","360000", @url, @token)

          case response
            when Net::HTTPOK
              json = JSON.parse(response.body)
              track(json['id'])
            when Net::HTTPAccepted
              json = JSON.parse(response.body)
              track(json['id'])
            else
              Put.error response.body
              Put.error response.message
          end
        end
      end

      # Finds Container model from array by hostname
      def find(hostname)
        @environment.containers.find {|cont| cont.hostname.include?(hostname)}
      end

      # Check request response status
      def status(response)
        case response
          when Net::HTTPOK
            response = JSON.parse(response.body)
            if response['status'] == Configs::EnvironmentState::SUCCEEDED
              Put.success response['status']
              Put.info response['stdOut']
            elsif response['status'] == Configs::EnvironmentState::FAILED
              Put.error response['status']
              Put.info response['stdOut']
              Put.error response['stdErr']
            end
          else
           Put.error response.body
        end
      end
    end
  end
end