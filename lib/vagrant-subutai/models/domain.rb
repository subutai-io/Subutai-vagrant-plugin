module VagrantSubutai
  module Models
    class Domain
      attr_accessor :protocol,       # protocol HTTP, HTTPS or tcp etc
                    :name,           # domain name ex: subutai.io
                    :internal_port,  # internal container port 
                    :external_port,  # expernal port
                    :container_name  # Container name
    end
  end  
end