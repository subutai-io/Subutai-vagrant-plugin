require_relative '../../vagrant-subutai'

module VagrantSubutai
  module Blueprint
    class AnsibleController
      attr_accessor :ansible      # ansible model
                    :environment  # environment model

      def initialize(ansible, environment)
        @ansible = ansible
        @environment = environment
      end

      # Adds template hosts to ansible configuration
      # /etc/ansible/hosts
      def hosts

      end

      # Runs ansible playbook
      def run
      end
    end
  end
end

# TODO
# 1. change ansible hosts
# 2. run ansible playbook

# bash /root/get_unzip.sh https://github.com/platium1/app3/archive/master.zip
# cd /tmp/app3-master/
# ansible-playbook  main.yml  -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars {'key': 'value'}