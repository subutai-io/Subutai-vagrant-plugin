require 'yaml'
require 'digest'

require_relative 'subutai_net'
require_relative 'subutai_hooks'

# Vagrant Driven Subutai Configuration
# noinspection RubyTooManyMethodsInspection
module SubutaiConfig
  LOG_MODES = %i[debug info warn error].freeze
  PARENT_DIR = './.vagrant'.freeze
  GENERATED_FILE = PARENT_DIR + '/generated.yml'.freeze
  CONF_FILE = File.expand_path('./vagrant-subutai.yml').freeze
  USER_CONF_FILE = File.expand_path('~/.vagrant-subutai/vagrant-subutai.yml').freeze
  SUBUTAI_ENVIRONMENTS = %i[prod master dev sysnet].freeze

  # Without a variable key listed here it will not get pulled in from
  # the environment, or from any of the vagrant-subutai.yml conf files
  USER_PARAMETERS = %i[
    DESIRED_CONSOLE_PORT
    DESIRED_SSH_PORT
    ALLOW_INSECURE
    SUBUTAI_ENV
    SUBUTAI_CPU
    SUBUTAI_RAM
    SUBUTAI_PEER
    SUBUTAI_SNAP
    SUBUTAI_DESKTOP
    SUBUTAI_MAN_TMPL
    APT_PROXY_URL
    PROVISION
    BRIDGE
    AUTHORIZED_KEYS
    PASSWORD_OVERRIDE
  ].freeze
  
  GENERATED_PARAMETERS = %i[
    _BRIDGED
    _CONSOLE_PORT
    _BASE_MAC
    _SSH_PORT
    _LOG_MODE
    _ALT_SNAP
    _ALT_SNAP_MD5
    _ALT_SNAP_MD5_LAST
    _ALT_MANAGEMENT
    _ALT_MANAGEMENT_MD5
    _ALT_MANAGEMENT_MD5_LAST
  ].freeze

  # Used for testing
  @conf_file_override = nil

  # Vagrant command currently being executed, must not be nil
  @cmd = nil

  # Hash of generated/calculated settings preserved through commands
  @generated = {}

  # Smart defaults to use for configuration settings
  @defaults = {
    # Implemented configuration parameters
    DESIRED_CONSOLE_PORT: 9999,      # integer for console port
    DESIRED_SSH_PORT: 4567,          # integer for console port
    ALLOW_INSECURE: false,           # boolean to enable insecure CDN and snap
    SUBUTAI_ENV: :prod,              # subutai environment to use
    SUBUTAI_PEER: true,              # to provision or not console (peer)
    SUBUTAI_RAM: 4096,               # RAM memory assigned to the vm
    SUBUTAI_CPU: 2,                  # virtual CPU's assign to the vm

    # Configuration parameters below have not been implemented
    SUBUTAI_SNAP: nil,               # alternative snap to provision
    SUBUTAI_DESKTOP: false,          # install desktop with tray and p2p client
    SUBUTAI_MAN_TMPL: nil,           # provision alternative management template
    APT_PROXY_URL: nil,              # configure apt proxy URL
    PROVISION: true                  # to provision or not to
  }

  # User provided configuration settings
  @config = @defaults.clone

  @logging = nil

  @bridged = false

  def self.write?
    raise 'SubutaiConfig.cmd not set' if @cmd.nil?
    @cmd == 'up'
  end

  def self.delete?
    raise 'SubutaiConfig.cmd not set' if @cmd.nil?
    @cmd == 'destroy'
  end

  def self.read?
    raise 'SubutaiConfig.cmd not set' if @cmd.nil?
    @cmd != 'up'
  end

  def self.generated?(key)
    GENERATED_PARAMETERS.include? key
  end

  def self.boolean?(key)
    if get(key.to_sym) == 'true' || get(key.to_sym) == true
      true
    elsif get(key.to_sym) == 'false' || get(key.to_sym) == false
      false
    elsif get(key.to_sym).nil?
      false
    else
      raise "#{key} value #{get(key.to_sym)} is not a boolean"
    end
  end

  def self.provision_snap?
    return false unless boolean?(:PROVISION)
    return false if get(:_ALT_SNAP).nil?
    return false if get(:_ALT_SNAP_MD5) == get(:_ALT_SNAP_MD5_LAST)
    return false unless %w[up provision].include?(@cmd)
    true
  end

  def self.snap_provisioned!
    put(:_ALT_SNAP_MD5_LAST, get(:_ALT_SNAP_MD5), true) if provision_snap?
  end

  def self.bridged!
    @bridged = true
  end

  def self.provision_management?
    return false unless boolean?(:PROVISION)
    return false if get(:_ALT_MANAGEMENT).nil?
    return false if get(:_ALT_MANAGEMENT_MD5) == get(:_ALT_MANAGEMENT_MD5_LAST)
    return false unless %w[up provision].include?(@cmd)
    true
  end

  def self.management_provisioned!
    put(:_ALT_MANAGEMENT_MD5_LAST, get(:_ALT_MANAGEMENT_MD5), true)\
      if provision_management?
  end

  def self.cmd
    @cmd
  end

  def self.config
    @config
  end

  def self.override_conf_file(filepath)
    @conf_file_override = filepath
  end

  def self.conf_file
    return CONF_FILE if @conf_file_override.nil?
    @conf_file_override
  end

  def self.get(key)
    key_sym = key.to_sym

    if key_sym == :SUBUTAI_ENV
      env = @config[key_sym].to_sym
      raise "#{env} invalid SUBUTAI_ENV" \
        unless SUBUTAI_ENVIRONMENTS.include?(env)
    end

    @config[key_sym]
  end

  # Write through to save configuration values
  def self.put(key, value, do_store)
    raise "Undefined configuration parameter: #{key}" \
      unless USER_PARAMETERS.include?(key.to_sym)     \
      || GENERATED_PARAMETERS.include?(key.to_sym)
    @config.store(key.to_sym, value)
    @generated.store(key.to_sym, value) if generated? key

    store if do_store
    value
  end

  # Load generated values preserved across vagrant commands
  def self.load_generated
    return false unless File.exist?(GENERATED_FILE)
    temp = YAML.load_file(GENERATED_FILE)
    temp.each do |key, value|
      @generated.store(key.to_sym, value)
      @config.store(key.to_sym, value)
    end
  end

  # Stores ONLY generated configuration from YAML files
  def self.store
    FileUtils.mkdir_p(PARENT_DIR) unless Dir.exist?(PARENT_DIR)
    stringified = Hash[@generated.map { |k, v| [k.to_s, v.to_s] }]
    File.open(GENERATED_FILE, 'w') { |f| f.write stringified.to_yaml }
    true
  end

  def self.set_env(key, value)
    raise "Invalid #{key} value of #{value}: use prod, master, or dev" \
          unless SUBUTAI_ENVIRONMENTS.include?(value)
    @config.store(key, value)
  end

  def self.load_config_file(config_file)
    temp = YAML.load_file(config_file)
    temp.each_key do |key|
      raise "Invalid key in YAML file: '#{key}'" \
          unless USER_PARAMETERS.include?(key.to_sym)

      if key.to_sym == :SUBUTAI_ENV
        set_env(key.to_sym, temp[key].to_sym)
      elsif !temp[key].nil?
        @config.store(key.to_sym, temp[key])
      end
    end
  end

  def self.do_handlers
    return false unless %w[up provision].include? @cmd
    file = snap_handler(get(:SUBUTAI_SNAP))
    unless file.nil?
      put(:_ALT_SNAP, file, true) if provision_snap?
      put(:_ALT_SNAP_MD5, Digest::MD5.file(file).to_s, true) if provision_snap?
    end

    file = management_handler(get(:SUBUTAI_MAN_TMPL))
    unless file.nil?
      put(:_ALT_MANAGEMENT, file, true) if provision_management?
      put(:_ALT_MANAGEMENT_MD5, Digest::MD5.file(file).to_s, true) \
        if provision_management?
    end
    true
  end

  # NOTE: Console port ONLY needed in nat mode
  # NOTE: SSH port only needed in bridged mode
  def self.do_network(provider)
    # set the next available console port if provisioning a peer in nat mode
    put(:_CONSOLE_PORT, find_port(get(:DESIRED_CONSOLE_PORT)), true) \
      if !@bridged && boolean?(:SUBUTAI_PEER) &&
         get(:_CONSOLE_PORT).nil? &&
         write?

    # set the SSH port if we are using bridged mode
    put(:_SSH_PORT, find_port(get(:DESIRED_SSH_PORT)), true) \
      if @bridged && get(:_SSH_PORT).nil? && write?

    put(:_BASE_MAC, find_mac(provider), true) \
      if @bridged && get(:_BASE_MAC).nil? && write?

    put(:_BRIDGED, @bridged, true) if write?
  end

  # Loads the generated and user configuration from YAML files
  def self.load_config(cmd, provider)
    raise 'SubutaiConfig.cmd not set' if cmd.nil?
    @cmd = cmd

    # Load YAML based user and local configuration if they exist
    load_config_file(CONF_FILE) if File.exist?(CONF_FILE)
    load_config_file(USER_CONF_FILE) if File.exist?(USER_CONF_FILE)
    load_generated

    # Load overrides from the environment, and generated configurations
    ENV.each do |key, value|
      put(key.to_sym, value, false) if USER_PARAMETERS.include? key.to_sym
    end
    do_handlers
    do_network(provider)
  end

  def self.reset
    @cmd = nil
    @config = @defaults.clone
    @generated = {}
    @conf_file_override = nil
  end

  # Destroys the generated file if vagrant destroy is used
  def self.cleanup
    cleanup! if delete?
  end

  def self.cleanup!
    reset
    File.delete GENERATED_FILE if File.exist?(GENERATED_FILE)
  end

  def self.logging!(mode)
    return (@logging = nil) if mode.nil?
    raise "Invalid logging mode #{mode}" unless LOG_MODES.include?(mode)
    @logging = mode
    puts "Logging mode set to #{mode}"
  end

  def self.log(cmds, message)
    return if @logging.nil?
    puts message if !cmds.nil? && cmds.include?(@cmd)
  end

  def self.log_mode(modes, cmds, message)
    return if @logging.nil?
    puts message if cmds.include?(@cmd) && modes.include?(@logging)
  end

  def self.print
    return if @logging.nil?
    puts
    puts ' ==> User provided configuration: '
    puts ' --------------------------------------------------------------------'

    @config.each do |key, value|
      puts "#{('       ' + key.to_s).ljust(29)} => #{value}" \
        unless generated? key
    end

    puts
    puts ' ==> Generated settings preserved across command runs:'
    puts ' --------------------------------------------------------------------'

    @config.each do |key, value|
      puts "#{('     + ' + key.to_s).ljust(29)} => #{value}" if generated? key
    end
  end
end

at_exit do
  SubutaiConfig.cleanup unless SubutaiConfig.cmd.nil?
end
