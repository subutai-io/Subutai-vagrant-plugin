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
            response = Rest::SubutaiConsole.command("echo \"#{container.containerName} ansible_user=root template=#{hostname} ansible_ssh_host=#{container.ip}\" >> /etc/ansible/hosts", @environment.ansible_host_id, "/root","1000", @url, @token)
            status(response)
          end
        end
      end

      # Downloads ansible source
      def download
        Put.info "\nStarted downloading ansible source...."
        response = Rest::SubutaiConsole.command("ansible-playbook download.json -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars '{ \"source_url\": \"#{@ansible.source_url}\"}'", @environment.ansible_host_id, "/root","360000", @url, @token)
        status(response)
      end

      # Runs ansible playbook
      def run
        Put.info "\nStarted running ansible playbook may be take too long time please wait......."
        if @ansible.extra_vars.empty?
          response = Rest::SubutaiConsole.command("cd /root/master/*/;ansible-playbook #{@ansible.ansible_playbook} -e 'ansible_python_interpreter=/usr/bin/python3'", @environment.ansible_host_id, "/root","360000", @url, @token)
          status(response)
        else
          extra_vars = {}
          @ansible.extra_vars.each do |extra_var|
            extra_var.map {|k, v| extra_vars[k] = v }
          end
          response = Rest::SubutaiConsole.command("cd /root/master/*/;ansible-playbook #{@ansible.ansible_playbook} -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars '#{extra_vars.to_json}'", @environment.ansible_host_id, "/root","360000", @url, @token)
          status(response)
        end
      end

      # Finds Container model from array by hostname
      def find(hostname)
        @environment.containers.find {|cont| cont.hostname == hostname}
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