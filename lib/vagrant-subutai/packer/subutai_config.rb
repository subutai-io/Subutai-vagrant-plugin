require 'yaml'
require 'digest'
require 'net/https'
require 'uri'
require 'json'

require_relative 'subutai_net'
require_relative 'subutai_hooks'
require_relative 'subutai_validation'
require_relative '../../../lib/vagrant-subutai/util/powershell'

# Vagrant Driven Subutai Configuration
# noinspection RubyTooManyMethodsInspection
module SubutaiConfig
  LOG_MODES = %i[debug info warn error].freeze
  PARENT_DIR = './.vagrant'.freeze
  GENERATED_FILE = PARENT_DIR + '/generated.yml'.freeze
  CONF_FILE = File.expand_path('./vagrant-subutai.yml').freeze
  USER_CONF_FILE = File.expand_path('~/.vagrant-subutai/vagrant-subutai.yml').freeze
  SUBUTAI_ENVIRONMENTS = %i[prod master dev sysnet].freeze
  SUBUTAI_SCOPES = %i[Public Private Shared].freeze
  SUBUTAI_ENV_TYPES = %i[bazaar peer].freeze

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
    SUBUTAI_DESKTOP
    SUBUTAI_MAN_TMPL
    APT_PROXY_URL
    PROVISION
    BLUEPRINT_NO_AUTO
    BRIDGE
    AUTHORIZED_KEYS
    PASSWORD_OVERRIDE
    DISK_SIZE
    SUBUTAI_ENV_TYPE
    SUBUTAI_NAME
    SUBUTAI_SCOPE
    SUBUTAI_USERNAME
    SUBUTAI_PASSWORD
    USER_VARIABLES
    BAZAAR_EMAIL
    BAZAAR_PASSWORD
    BAZAAR_NO_AUTO
    SUBUTAI_DISK_PATH
    LIBVIRT_USER
    LIBVIRT_HOST
    LIBVIRT_PORT
    LIBVIRT_MACVTAP
    LIBVIRT_NO_BRIDGE
    LIBVIRT_POOL
    SUBUTAI_DISK
    BRIDGE_VIRTUALBOX
    BRIDGE_PARALLELS
    BRIDGE_VMWARE
    BRIDGE_KVM
    BRIDGE_HYPERV
    ENABLE_MAC_CHECK
  ].freeze
  
  GENERATED_PARAMETERS = %i[
    _BRIDGED
    _CONSOLE_PORT
    _BASE_MAC
    _SSH_PORT
    _LOG_MODE
    _ALT_MANAGEMENT
    _ALT_MANAGEMENT_MD5
    _ALT_MANAGEMENT_MD5_LAST
    _DISK_SIZE
    _DISK_PORT
    _DISK_PATHES
    _IP_HYPERV
    _IP_PEER
  ].freeze

  # Used for testing
  @conf_file_override = nil

  # Vagrant command currently being executed, must not be nil
  @cmd = nil

  # Vagrant provider name
  @provider = nil

  # Hash of generated/calculated settings preserved through commands
  @generated = {}

  # Smart defaults to use for configuration settings
  @defaults = {
    # Implemented configuration parameters
    DESIRED_CONSOLE_PORT: 9999,      # integer for console port
    DESIRED_SSH_PORT: 4567,          # integer for console port
    ALLOW_INSECURE: false,           # boolean to enable insecure CDN
    SUBUTAI_ENV: :prod,              # subutai environment to use
    SUBUTAI_PEER: true,              # to provision or not console (peer)
    SUBUTAI_RAM: 4096,               # RAM memory assigned to the vm
    SUBUTAI_CPU: 2,                  # virtual CPU's assign to the vm
    SUBUTAI_NAME: 'My Peer',         # PeerOS name
    SUBUTAI_SCOPE: 'Public',         # PeerOS scope
    SUBUTAI_USERNAME: 'admin',       # PeerOS default username
    LIBVIRT_PORT: 22,                # Libvirt kvm remote operation ssh port
    LIBVIRT_MACVTAP: false,          # Libvirt macvtap interface
    BAZAAR_NO_AUTO: false,           # PeerOs automatic registration to Bazaar (turn on(false), turn off(true))
    PROVISION: true,                 # to provision or not to
    LIBVIRT_POOL: 'default',         # Libvirt pool name
    BLUEPRINT_NO_AUTO: false,        # Auto provision blueprints if present

    SUBUTAI_DESKTOP: false,          # install desktop with tray and p2p client
    SUBUTAI_MAN_TMPL: nil,           # provision alternative management template
    APT_PROXY_URL: nil,              # configure apt proxy URL
    ENABLE_MAC_CHECK: false,                # mac addr checks

    # provider with value
    hyper_v: 'hyperv',
    parallels: 'parallels',
    virtualbox: 'virtualbox',
    libvirt: 'libvirt',
    vmware: 'vmware_desktop'
  }

  # User provided configuration settings
  @config = @defaults.clone

  @logging = nil

  @bridged = false

  @url_of_cdn = 'https://cdn.subutai.io:8338/kurjun/rest'

  def self.write?
    raise 'SubutaiConfig.cmd not set' if @cmd.nil?
    @cmd == 'up'
  end

  def self.reload?
    raise 'SubutaiConfig.cmd not set' if @cmd.nil?
    @cmd == 'reload'
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

  def self.bridged!
    @bridged = true
  end

  # The "general" BRIDGE configuration property should be overridden or
  # set to the hypervisor/provider specific
  def self.bridge
    case provider
      when :hyper_v
        SubutaiConfig.put(:BRIDGE, get(:BRIDGE_HYPERV), true) unless get(:BRIDGE_HYPERV).nil?
      when :parallels
        SubutaiConfig.put(:BRIDGE, get(:BRIDGE_PARALLELS), true) unless get(:BRIDGE_PARALLELS).nil?
      when :vmware
        SubutaiConfig.put(:BRIDGE, get(:BRIDGE_VMWARE), true) unless get(:BRIDGE_VMWARE).nil?
      when :libvirt
        SubutaiConfig.put(:BRIDGE, get(:BRIDGE_KVM), true) unless get(:BRIDGE_KVM).nil?
      when :virtualbox
        SubutaiConfig.put(:BRIDGE, get(:BRIDGE_VIRTUALBOX), true) unless get(:BRIDGE_VIRTUALBOX).nil?
    end
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

  def self.provider
    @provider
  end

  def self.config
    @config
  end

  # Now we support both configuration parameter DISK_SIZE and SUBUTAI_DISK
  # SUBUTAI_DISK overrides DISK_SIZE
  def self.disk_size
    put(:DISK_SIZE, get(:SUBUTAI_DISK), true)  unless get(:SUBUTAI_DISK).nil?
  end

  def self.get_grow_by
    disk = get(:DISK_SIZE)

    if disk.nil?
      nil
    else
      disk = disk.to_i
      generated_disk = get(:_DISK_SIZE)
      grow_by = 0

      if generated_disk.nil?
        grow_by = disk - 100 # default Subutai disk is 100 gigabytes
      else
        grow_by = disk - (generated_disk.to_i + 100) # HERE Applied math BEDMAS rule
      end
      grow_by
    end
  end

  def self.url_of_cdn
    @url_of_cdn
  end

  def self.url_of_cdn=(cdn_url)
    @url_of_cdn = cdn_url
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
    stringified = Hash[@generated.map { |k, v| [k.to_s, v] }]
    File.open(GENERATED_FILE, 'w') { |f| f.write stringified.to_yaml }

    true
  end

  def self.set_env(key, value)
    raise "Invalid #{key} value of #{value}: use prod, master, or dev" \
          unless SUBUTAI_ENVIRONMENTS.include?(value)
    @config.store(key, value)
  end

  def self.set_env_type(key, value)
    raise "Invalid #{key} value of #{value}: use bazaar or peer" \
          unless SUBUTAI_ENV_TYPES.include?(value.downcase)
    @config.store(key, value.downcase)
  end

  def self.set_scope(key, value)
    raise "Invalid #{key} value of #{value}: use public, private or shared" \
          unless SUBUTAI_SCOPES.include?(value.capitalize)
    @config.store(key, value.capitalize)
  end

  def self.load_config_file(config_file)
    temp = YAML.load_file(config_file)
    temp.each_key do |key|
      raise "Invalid key in YAML file: '#{key}'" \
          unless USER_PARAMETERS.include?(key.to_sym)

      SubutaiValidation.validate(key.to_sym, temp[key]) unless delete?
      @config.store(key.to_sym, temp[key]) unless temp[key].nil?
    end
  end

  def self.do_handlers
    return false unless %w[up provision].include? @cmd

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
    put(:_CONSOLE_PORT, find_port(get(:DESIRED_CONSOLE_PORT)), write?) \
      if boolean?(:SUBUTAI_PEER) && get(:_CONSOLE_PORT).nil? && (write? || delete? || read?)

    # set the SSH port if we are using bridged mode
    put(:_SSH_PORT, find_port(get(:DESIRED_SSH_PORT)), true) \
      if @bridged && get(:_SSH_PORT).nil? && write?

    put(:_BASE_MAC, find_mac(provider), true) \
      if @bridged && get(:_BASE_MAC).nil? && write? && get(:ENABLE_MAC_CHECK)

    put(:_BRIDGED, @bridged, true) if write?

    generate_switch if provider == :hyper_v && write?
  end

  # Generates Virtual Switch for Hyper-V
  def self.generate_switch
    unless VagrantSubutai::Util::Powershell.execute(File.join(File.expand_path(File.dirname(__FILE__)), 'script/create_virtual_switch.ps1'))
      Put.error("Failed to create virtual switch")
    end
  end

  def self.machine_id(provider)
    id = nil

    case provider
    when :hyper_v
      id = File.join(PARENT_DIR, 'machines/default/hyperv/id')
    when :parallels
      id = File.join(PARENT_DIR, 'machines/default/parallels/id')
    end

    File.read(id) if File.exist?(id)
  end

  # Loads the generated and user configuration from YAML files
  def self.load_config(cmd, provider)
    raise 'SubutaiConfig.cmd not set' if cmd.nil?
    @cmd = cmd
    @provider = provider

    # Load YAML based user and local configuration if they exist
    load_config_file(USER_CONF_FILE) if File.exist?(USER_CONF_FILE)
    load_config_file(conf_file) if File.exist?(conf_file)
    load_generated

    # Write empty file with name provider
    # ControlCenter uses for checking provider of peer
    unless File.exist?(File.join(PARENT_DIR, @defaults[@provider]))
      if Dir.exist?(PARENT_DIR) && write?
        file = File.new(File.join(PARENT_DIR, @defaults[@provider]), 'w') 
        file.close
      end
    end

    # Load overrides from the environment, and generated configurations
    ENV.each do |key, value|
      put(key.to_sym, value, false) if USER_PARAMETERS.include? key.to_sym
    end

    # override configuration parameters BRIDGE by specified provider bridge name
    bridge
    # SUBUTAI_DISK overrides DISK_SIZE
    disk_size

    do_handlers
    do_network(provider)
  end

  def self.reset
    @cmd = nil
    @provider = nil
    @config = @defaults.clone
    @generated = {}
    @conf_file_override = nil
  end


  def self.cleanup
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

  def self.get_latest_id_artifact(owner, artifact_name)
    ""  # send empty id.
  end
end

at_exit do
  SubutaiConfig.cleanup unless SubutaiConfig.cmd.nil?
end

