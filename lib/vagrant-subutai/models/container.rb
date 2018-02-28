# Blueprint container model

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

      def ansible
        @hostname = "ansible"
        @container_size = "TINY"
        @name = "ansible"
        @owner = "ec54e1cff2341cdc55be5e961cfd15b4f97087e8"
      end
    end
  end
end