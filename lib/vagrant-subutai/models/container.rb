
module VagrantSubutai
  module Models
    class Container
      attr_accessor :hostname,
                    :name,
                    :container_size,
                    :owner,
                    :resource_host_id,
                    :peer_id,
                    :peer_criteria,
                    :port_mapping

      def template=(value)
        temp = value.split('@')
        @template = value
        @name = temp[0]
        @owner = temp[1]
      end

      def template
        @template
      end
    end
  end
end