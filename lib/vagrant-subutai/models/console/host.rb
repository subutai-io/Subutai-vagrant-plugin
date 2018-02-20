module VagrantSubutai
  module Models
    module Console
      class Host
        attr_accessor :status,
                      :name,
                      :quota,          # json object {"cpu": int, "ram": int, "disk": int}
                      :interfaces,     # json array {"interfaceName": string, "ip": string}
                      :environmentId,
                      :vlan,
                      :id,
                      :hostname,
                      :arch
      end
    end
  end
end