module VagrantSubutai
  module Models
    class Ansible
      attr_accessor :extra_vars,         # Array of JSON objects { "key": string,  "value": string }
                    :source_url,
                    :ansible_playbook,
                    :groups              # Array of JSON objects { "name": string, "hostnames": [ string ] }

      def context
        self.instance_variables.map do |attribute|
          { attribute => self.instance_variable_get(attribute) }
        end
      end
    end
  end
end