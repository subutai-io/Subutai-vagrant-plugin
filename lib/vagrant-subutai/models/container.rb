
module VagrantSubutai
  module Models
    class Container
      attr_accessor :hostname,
                    :container_size,
                    :template_id,
                    :resource_host_id,
                    :peer_id,
                    :template,
                    :peer_criteria,
                    :port_mapping
    end
  end
end