module VagrantSubutai
  module Models
    module Console
      class Environment
        attr_accessor :id,
                      :name,
                      :status,
                      :containers # Array Container model
      end
    end
  end
end