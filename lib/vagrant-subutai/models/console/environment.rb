# Subutai Console REST API environment model

module VagrantSubutai
  module Models
    module Console
      class Environment
        attr_accessor :id,
                      :name,
                      :status,
                      :containers,               # Array of Container models
                      :ansible_host_id,          # Ansible host id
                      :ansible_container_state   # Ansible container state
      end
    end
  end
end