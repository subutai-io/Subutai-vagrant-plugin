# Subutai Console REST API container model

module VagrantSubutai
  module Models
    module Console
      class Container
        attr_accessor :id,
                      :environmentId,
                      :hostname,
                      :ip,
                      :templateName,
                      :templateId,
                      :type,
                      :arch,
                      :tags,           # JSON array
                      :peerId,
                      :hostId,
                      :local,          # boolean
                      :state,
                      :rhId,
                      :quota,          # JSON object {"containerSize": string, "cpu": string, "ram": string, "disk": string}
                      :dataSource,
                      :containerName
      end
    end
  end
end