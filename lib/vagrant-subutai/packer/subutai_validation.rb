require 'uri'
require 'json'
require_relative 'subutai_config'

module SubutaiValidation

  USER_CONF_PARAMS_TYPE = {
    "DESIRED_CONSOLE_PORT": :int,
    "DESIRED_SSH_PORT":     :int,
    "ALLOW_INSECURE":       :bool,
    "SUBUTAI_ENV":          :enum,
    "SUBUTAI_CPU":          :int,
    "SUBUTAI_RAM":          :int,
    "SUBUTAI_PEER":         :bool,
    "SUBUTAI_DESKTOP":      :bool,
    "SUBUTAI_MAN_TMPL":     :path,
    "APT_PROXY_URL":        :url,
    "PROVISION":            :bool,
    "BRIDGE":               :string,
    "AUTHORIZED_KEYS":      :path,
    "PASSWORD_OVERRIDE":    :string,
    "DISK_SIZE":            :int,
    "SUBUTAI_DISK":         :int,
    "SUBUTAI_ENV_TYPE":     :enum,
    "SUBUTAI_NAME":         :string,
    "SUBUTAI_SCOPE":        :enum,
    "SUBUTAI_USERNAME":     :string,
    "SUBUTAI_PASSWORD":     :string,
    "USER_VARIABLES":       :json_object,
    "BAZAAR_EMAIL":         :string,
    "BAZAAR_PASSWORD":      :string,
    "BAZAAR_NO_AUTO":       :bool,
    "BLUEPRINT_NO_AUTO":    :bool,
    "SUBUTAI_DISK_PATH":    :path,
    "LIBVIRT_USER":         :string,
    "LIBVIRT_HOST":         :string,
    "LIBVIRT_POOL":         :string,
    "LIBVIRT_PORT":         :int,
    "LIBVIRT_MACVTAP":      :bool,
    "LIBVIRT_NO_BRIDGE":    :bool,
    "BRIDGE_VIRTUALBOX":    :string,
    "BRIDGE_PARALLELS":     :string,
    "BRIDGE_VMWARE":        :string,
    "BRIDGE_KVM":           :string,
    "BRIDGE_HYPERV":        :string,
    "ENABLE_MAC_CHECK":     :bool
  }.freeze

  def self.validate(key, value)
    case USER_CONF_PARAMS_TYPE[key]
      when :enum
        if key == :SUBUTAI_ENV
          SubutaiConfig.set_env(key, value.to_sym)
        elsif key == :SUBUTAI_SCOPE
          SubutaiConfig.set_scope(key, value.to_sym)
        elsif key == :SUBUTAI_ENV_TYPE
          SubutaiConfig.set_env_type(key, value.to_sym)
        end
      when :int
        raise "\e[33m\n\nInvalid #{key} type of #{value}: use int type \n\e[0m" unless value.is_a?(Integer)
      when :path
        raise "\e[33m\n\nPermission denied or invalid #{key} path of #{value}: use valid path \n\e[0m" unless writable_and_exist?(value)
      when :string
        raise "\e[33m\n\nInvalid #{key} type of #{value}: use string type \n\e[0m" unless value.is_a?(String)
      when :bool
        raise "\e[33m\n\nInvalid #{key} type of #{value}: use bool type \n\e[0m" unless bool?(value)
      when :url
        raise "\e[33m\n\nInvalid #{key} url of #{value}: use valid url \n\e[0m" unless value =~ URI::regexp
      when :json_object
        raise "\e[33m\n\nInvalid #{key} json of #{value}: use json object \n\e[0m" unless is_json?(value)
    end

    true
  end

  def self.bool?(value)
    if value == 'true' || value == true
      true
    elsif value == 'false' || value == false
      true
    else
      false
    end
  end

  def self.writable_and_exist?(value)
    if File.exist?(value) && File.writable?(value)
      return true
    end

    false
  end

  def self.is_json?(json)
    if json.kind_of?(Hash)
      return true
    end

    begin
      JSON.parse(json)
    rescue JSON::ParserError
      return false
    end

    true
  end
end