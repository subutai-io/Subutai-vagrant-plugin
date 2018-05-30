require 'rubygems'
require 'test/unit'
require 'fileutils'

require_relative '../lib/vagrant-subutai/packer/subutai_config'
require_relative '../lib/vagrant-subutai/put'

# Tests the SubutaiConfig module
class SubutaiConfigTest < Test::Unit::TestCase
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    FileUtils.rm_rf SubutaiConfig::PARENT_DIR
    assert_path_not_exist(SubutaiConfig::PARENT_DIR)

    File.delete(SubutaiConfig::CONF_FILE) \
      if File.exist?(SubutaiConfig::CONF_FILE)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    SubutaiConfig.cleanup!
  end

  # checks defaults without changing any values
  def defaults?
    SubutaiConfig.load_config 'up', :virtualbox
    assert_equal(SubutaiConfig.config.count, 10)

    assert_true(SubutaiConfig.get(:SUBUTAI_PEER))
    assert_false(SubutaiConfig.get(:ALLOW_INSECURE))
    assert_false(SubutaiConfig.get(:SUBUTAI_DESKTOP))

    assert_equal(SubutaiConfig.get(:DESIRED_CONSOLE_PORT), 9999)
    assert_equal(SubutaiConfig.get(:SUBUTAI_ENV), :prod)
    assert_equal(SubutaiConfig.get(:SUBUTAI_RAM), 4096)
    assert_equal(SubutaiConfig.get(:SUBUTAI_CPU), 2)

    assert_nil(SubutaiConfig.get(:SUBUTAI_MAN_TMPL))
    assert_nil(SubutaiConfig.get(:APT_PROXY_URL))

    SubutaiConfig::GENERATED_PARAMETERS.each do |p|
      assert_nil(SubutaiConfig.get(p))
    end
  end

  # Raise exception without setting valid cmd
  def test_no_cmd
    assert_raise do
      SubutaiConfig.load_config(nil, :virtualbox)
    end
  end

  def test_cleanup!
    SubutaiConfig.load_config('up', :virtualbox)
    SubutaiConfig.put('_CONSOLE_PORT', 10_394, true)
    SubutaiConfig.put('SUBUTAI_PEER', false, true)
    SubutaiConfig.cleanup!

    assert_path_not_exist(SubutaiConfig::GENERATED_FILE, 'generated.yaml')
  end

  def test_cleanup
    SubutaiConfig.load_config('up', :virtualbox)
    SubutaiConfig.put('SUBUTAI_PEER', true, true)
    assert_path_exist(SubutaiConfig::GENERATED_FILE, 'generated.yaml')

    SubutaiConfig.cleanup
    assert_path_exist(SubutaiConfig::GENERATED_FILE, 'generated.yaml')

    SubutaiConfig.put('SUBUTAI_PEER', true, true)
    assert_path_exist(SubutaiConfig::GENERATED_FILE, 'generated.yaml')

    SubutaiConfig.load_config('destroy', :virtualbox)
    assert_path_exist(SubutaiConfig::GENERATED_FILE, 'generated.yaml')

    SubutaiConfig.cleanup!
    assert_path_not_exist(SubutaiConfig::GENERATED_FILE, 'generated.yaml')
  end

  def test_get_put_up
    SubutaiConfig.load_config('up', :virtualbox)

    #
    # Bunch of tests for User Parameters
    #

    # ALLOW_INSECURE
    assert_false(SubutaiConfig.get(:ALLOW_INSECURE))
    assert_true(SubutaiConfig.put(:ALLOW_INSECURE, true, true))
    assert_true(SubutaiConfig.get(:ALLOW_INSECURE))
    assert_true(SubutaiConfig.get('ALLOW_INSECURE'))

    assert_false(SubutaiConfig.put('ALLOW_INSECURE', false, true))
    assert_false(SubutaiConfig.get(:ALLOW_INSECURE))
    assert_false(SubutaiConfig.get('ALLOW_INSECURE'))

    # SUBUTAI_DESKTOP
    assert_false(SubutaiConfig.get(:SUBUTAI_DESKTOP))
    assert_true(SubutaiConfig.put(:SUBUTAI_DESKTOP, true, true))
    assert_true(SubutaiConfig.get(:SUBUTAI_DESKTOP))
    assert_true(SubutaiConfig.get('SUBUTAI_DESKTOP'))

    assert_false(SubutaiConfig.put('SUBUTAI_DESKTOP', false, true))
    assert_false(SubutaiConfig.get(:SUBUTAI_DESKTOP))
    assert_false(SubutaiConfig.get('SUBUTAI_DESKTOP'))

    # SUBUTAI_PEER
    assert_true(SubutaiConfig.get(:SUBUTAI_PEER))
    assert_false(SubutaiConfig.put(:SUBUTAI_PEER, false, true))
    assert_false(SubutaiConfig.get(:SUBUTAI_PEER))
    assert_false(SubutaiConfig.get('SUBUTAI_PEER'))

    assert_true(SubutaiConfig.put('SUBUTAI_PEER', true, true))
    assert_true(SubutaiConfig.get(:SUBUTAI_PEER))
    assert_true(SubutaiConfig.get('SUBUTAI_PEER'))

    # DESIRED_CONSOLE_PORT
    assert_equal(SubutaiConfig.get(:DESIRED_CONSOLE_PORT), 9999)
    assert_equal(7777, SubutaiConfig.put(:DESIRED_CONSOLE_PORT, 7777, true))
    assert_equal(SubutaiConfig.get(:DESIRED_CONSOLE_PORT), 7777)
    assert_equal(SubutaiConfig.get('DESIRED_CONSOLE_PORT'), 7777)

    assert_equal(SubutaiConfig.put('DESIRED_CONSOLE_PORT', 6666, true), 6666)
    assert_equal(SubutaiConfig.get(:DESIRED_CONSOLE_PORT), 6666)
    assert_equal(SubutaiConfig.get('DESIRED_CONSOLE_PORT'), 6666)

    # SUBUTAI_RAM
    assert_equal(SubutaiConfig.get(:SUBUTAI_RAM), 4096)
    assert_equal(8192, SubutaiConfig.put(:SUBUTAI_RAM, 8192, true))
    assert_equal(SubutaiConfig.get(:SUBUTAI_RAM), 8192)
    assert_equal(SubutaiConfig.get('SUBUTAI_RAM'), 8192)

    assert_equal(SubutaiConfig.put('SUBUTAI_RAM', 2048, true), 2048)
    assert_equal(SubutaiConfig.get(:SUBUTAI_RAM), 2048)
    assert_equal(SubutaiConfig.get('SUBUTAI_RAM'), 2048)

    # SUBUTAI_CPU
    assert_equal(SubutaiConfig.get(:SUBUTAI_CPU), 2)
    assert_equal(4, SubutaiConfig.put(:SUBUTAI_CPU, 4, true))
    assert_equal(SubutaiConfig.get(:SUBUTAI_CPU), 4)
    assert_equal(SubutaiConfig.get('SUBUTAI_CPU'), 4)

    assert_equal(SubutaiConfig.put('SUBUTAI_CPU', 6, true), 6)
    assert_equal(SubutaiConfig.get(:SUBUTAI_CPU), 6)
    assert_equal(SubutaiConfig.get('SUBUTAI_CPU'), 6)

    # SUBUTAI_ENV
    assert_equal(:prod, SubutaiConfig.get(:SUBUTAI_ENV))
    assert_equal(:dev, SubutaiConfig.put(:SUBUTAI_ENV, :dev, true))
    assert_equal(:dev, SubutaiConfig.get(:SUBUTAI_ENV))
    assert_equal(:dev, SubutaiConfig.get('SUBUTAI_ENV'))

    assert_equal(:prod, SubutaiConfig.put('SUBUTAI_ENV', :prod, true))
    assert_equal(:prod, SubutaiConfig.get(:SUBUTAI_ENV))
    assert_equal(:prod, SubutaiConfig.get('SUBUTAI_ENV'))

    # SUBUTAI_MAN_TMPL
    assert_nil(SubutaiConfig.get(:SUBUTAI_MAN_TMPL))
    pkg = './bogus/path/management.deb'
    assert_equal(pkg, SubutaiConfig.put(:SUBUTAI_MAN_TMPL, pkg, true))
    assert_equal(pkg, SubutaiConfig.get(:SUBUTAI_MAN_TMPL))
    assert_equal(pkg, SubutaiConfig.get('SUBUTAI_MAN_TMPL'))

    # APT_PROXY_URL
    assert_equal(SubutaiConfig.get(:APT_PROXY_URL), ENV['APT_PROXY_URL'])
    url = 'http://localhost:3124'
    assert_equal(url, SubutaiConfig.put(:APT_PROXY_URL, url, true))
    assert_equal(url, SubutaiConfig.get(:APT_PROXY_URL))
    assert_equal(url, SubutaiConfig.get('APT_PROXY_URL'))
  end

  def test_get_put_generated
    SubutaiConfig.load_config('up', :virtualbox)

    # _CONSOLE_PORT
    assert_equal(1234, SubutaiConfig.put(:_CONSOLE_PORT, 1234, true))
    assert_equal(1234, SubutaiConfig.get(:_CONSOLE_PORT))
    assert_equal(1234, SubutaiConfig.get('_CONSOLE_PORT'))

    # _ALT_MANAGEMENT
    assert_nil(SubutaiConfig.get(:_ALT_MANAGEMENT))
    pkg = './bogus/path.deb'
    assert_equal(pkg, SubutaiConfig.put(:_ALT_MANAGEMENT, pkg, true))
    assert_equal(pkg, SubutaiConfig.get(:_ALT_MANAGEMENT))
    assert_equal(pkg, SubutaiConfig.get('_ALT_MANAGEMENT'))
  end

  def test_print
    SubutaiConfig.load_config('up', :virtualbox)
    SubutaiConfig.put('_CONSOLE_PORT', '10009', true)
    SubutaiConfig.print
  end

  def test_up
    cmd = 'up'
    SubutaiConfig.load_config(cmd, :virtualbox)
    assert_equal(cmd, SubutaiConfig.cmd, 'cmd does not equal ' + cmd)
    SubutaiConfig.put('SUBUTAI_PEER', true, true)
    assert_path_exist(SubutaiConfig::GENERATED_FILE)
  end

  def test_destroy
    cmd = 'destroy'
    SubutaiConfig.load_config(cmd, :virtualbox)
    assert_equal(cmd, SubutaiConfig.cmd, 'cmd does not equal ' + cmd)
  end

  def test_seq0
    cmd = 'up'
    pkg = './bogus/path/management.deb'

    SubutaiConfig.load_config(cmd, :virtualbox)
    assert_equal(cmd, SubutaiConfig.cmd, 'cmd does not equal ' + cmd)
    assert_equal(pkg, SubutaiConfig.put(:SUBUTAI_MAN_TMPL, pkg, true))
    assert_equal(1234, SubutaiConfig.put(:_CONSOLE_PORT, 1234, true))
    assert_equal(pkg, SubutaiConfig.put(:_ALT_MANAGEMENT, pkg, true))
    assert_true(SubutaiConfig.put(:ALLOW_INSECURE, true, true))
    assert_true(SubutaiConfig.put(:SUBUTAI_DESKTOP, true, true))
    assert_false(SubutaiConfig.put(:SUBUTAI_PEER, false, true))
    assert_equal(7777, SubutaiConfig.put(:DESIRED_CONSOLE_PORT, 7777, true))
    assert_equal(8192, SubutaiConfig.put(:SUBUTAI_RAM, 8192, true))
    assert_equal(4, SubutaiConfig.put(:SUBUTAI_CPU, 4, true))
    assert_equal(:dev, SubutaiConfig.put(:SUBUTAI_ENV, :dev, true))

    SubutaiConfig.reset

    cmd = 'ssh'
    SubutaiConfig.load_config(cmd, :virtualbox)
    assert_equal(cmd, SubutaiConfig.cmd, 'cmd does not equal ' + cmd)
    assert_nil(SubutaiConfig.get(:SUBUTAI_MAN_TMPL))
    assert_false(SubutaiConfig.get(:ALLOW_INSECURE))
    assert_false(SubutaiConfig.get(:SUBUTAI_DESKTOP))
    assert_true(SubutaiConfig.get(:SUBUTAI_PEER))
    assert_equal(9999, SubutaiConfig.get(:DESIRED_CONSOLE_PORT))
    assert_equal(4096, SubutaiConfig.get(:SUBUTAI_RAM))
    assert_equal(2, SubutaiConfig.get(:SUBUTAI_CPU))
    assert_equal(:prod, SubutaiConfig.get(:SUBUTAI_ENV))

    # these should not be cleared out by the reset
    assert_equal(pkg, SubutaiConfig.get(:_ALT_MANAGEMENT))

    cmd = 'suspend'
    SubutaiConfig.load_config(cmd, :virtualbox)
    assert_equal(cmd, SubutaiConfig.cmd, 'cmd does not equal ' + cmd)

    cmd = 'resume'
    SubutaiConfig.load_config(cmd, :virtualbox)
    assert_equal(cmd, SubutaiConfig.cmd, 'cmd does not equal ' + cmd)
  end

  def test_unknown_key
    assert_raise do
      SubutaiConfig.load_config('up', :virtualbox)
      SubutaiConfig.put('foo', 'bar', true)
    end
  end

  def test_not_raise
    assert_nothing_raised do
      SubutaiConfig.override_conf_file('./test/subutai-validation-0.yml')
      SubutaiConfig.load_config('up', :virtualbox)
    end
  end

  def test_bad_env_subutai_yaml_0
    assert_raise do
      SubutaiConfig.override_conf_file('./test/subutai0.yaml')
      SubutaiConfig.load_config('up', :virtualbox)
    end
  end

  def test_bad_key_subutai_yaml_1
    assert_raise do
      SubutaiConfig.override_conf_file('./test/subutai1.yaml')
      SubutaiConfig.load_config('up', :virtualbox)
    end
  end

  def test_subutai_yaml_2
    SubutaiConfig.override_conf_file('./test/subutai2.yaml')
    SubutaiConfig.load_config('up', :virtualbox)
    SubutaiConfig.logging!(:debug)
    SubutaiConfig.print
    SubutaiConfig.log('up', 'dummy message')
    SubutaiConfig.log_mode([:debug], ['up'], 'dummy message')
    SubutaiConfig.print
    assert_equal(:master, SubutaiConfig.get(:SUBUTAI_ENV))
    assert_equal(9191, SubutaiConfig.get(:DESIRED_CONSOLE_PORT))
    assert_equal(2000, SubutaiConfig.get(:SUBUTAI_RAM))
    assert_equal(6, SubutaiConfig.get(:SUBUTAI_CPU))
    assert_false(SubutaiConfig.get(:SUBUTAI_PEER))
    assert_true(SubutaiConfig.get(:SUBUTAI_DESKTOP))
    assert_true(SubutaiConfig.get(:ALLOW_INSECURE))
    assert_equal('./test/management_test_file.deb', SubutaiConfig.get(:SUBUTAI_MAN_TMPL))

    if ENV['APT_PROXY_URL'].nil?
      assert_equal('http://some_server:4444', SubutaiConfig.get(:APT_PROXY_URL))
    else
      assert_equal(ENV['APT_PROXY_URL'], SubutaiConfig.get(:APT_PROXY_URL))
    end
  end


  def test_boolean?
    SubutaiConfig.load_config('up', :virtualbox)
    assert_true(SubutaiConfig.boolean?(:SUBUTAI_PEER))
    assert_false(SubutaiConfig.boolean?(:SUBUTAI_DESKTOP))
    assert_raise do
      SubutaiConfig.boolean?(:SUBUTAI_CPU)
    end
  end

  def test_raises
    assert_raise do
      SubutaiConfig.write?
    end
    assert_raise do
      SubutaiConfig.delete?
    end
    assert_raise do
      SubutaiConfig.read?
    end

    assert_not_nil(SubutaiConfig.config)

    SubutaiConfig.load_config('ssh', :virtualbox)
    assert_true(SubutaiConfig.read?)
  end

  def test_provision_management?
    SubutaiConfig.load_config('ssh', :virtualbox)
    configs = SubutaiConfig.config

    # Make it all negative for provisioning conditions
    configs.store(:PROVISION, false)
    configs.store(:_ALT_MANAGEMENT, nil)
    configs.store(:_ALT_MANAGEMENT_MD5, 'd41d8cd98f00b204e9800998ecf8427e')
    configs.store(:_ALT_MANAGEMENT_MD5_LAST, 'd41d8cd98f00b204e9800998ecf8427e')
    assert_false(SubutaiConfig.provision_management?)

    configs.store(:PROVISION, true)
    configs.store(:_ALT_MANAGEMENT, nil)
    configs.store(:_ALT_MANAGEMENT_MD5, 'd41d8cd98f00b204e9800998ecf8427e')
    configs.store(:_ALT_MANAGEMENT_MD5_LAST, 'd41d8cd98f00b204e9800998ecf8427e')
    assert_false(SubutaiConfig.provision_management?)

    configs.store(:PROVISION, true)
    configs.store(:_ALT_MANAGEMENT, './snap_script.sh')
    configs.store(:_ALT_MANAGEMENT_MD5, 'd41d8cd98f00b204e9800998ecf8427e')
    configs.store(:_ALT_MANAGEMENT_MD5_LAST, 'd41d8cd98f00b204e9800998ecf8427e')
    assert_false(SubutaiConfig.provision_management?)

    configs.store(:PROVISION, true)
    configs.store(:_ALT_MANAGEMENT, './snap_script.sh')
    configs.store(:_ALT_MANAGEMENT_MD5, 'd41d8cd98f00b204e9800998ecf8427e')
    configs.store(:_ALT_MANAGEMENT_MD5_LAST, nil)
    assert_false(SubutaiConfig.provision_management?)

    SubutaiConfig.load_config('ssh', :virtualbox)
    puts configs
    configs.store(:PROVISION, true)
    puts configs

    configs.store(:_ALT_MANAGEMENT, './test/snap_script.sh')
    configs.store(:_ALT_MANAGEMENT_MD5, 'd41d8cd98f00b204e9800998ecf8427e')
    configs.store(:_ALT_MANAGEMENT_MD5_LAST, nil)
    assert_false(SubutaiConfig.provision_management?)

    SubutaiConfig.management_provisioned!
  end

  def test_do_handlers
    SubutaiConfig.load_config('ssh', :virtualbox)
    configs = SubutaiConfig.config
    assert_false(SubutaiConfig.do_handlers)

    SubutaiConfig.load_config('up', :virtualbox)
    configs.store(:SUBUTAI_MAN_TMPL, './test/snap_script.sh')
    assert_true(SubutaiConfig.do_handlers)

    configs.store(:SUBUTAI_MAN_TMPL, './test/bad_snap_script.sh')
    assert_raise do
      SubutaiConfig.do_handlers
    end
  end

  def test_get_latest_artifact
    assert_equal('https://cdn.subutai.io:8338/kurjun/rest', SubutaiConfig.url_of_cdn)

    SubutaiConfig.load_config("up", :libvirt)
    assert_equal("", SubutaiConfig.get_latest_id_artifact("invalid", "vagrant-subutai-stretch-libvirt.box"))

    SubutaiConfig.cleanup!

    SubutaiConfig.load_config("destroy", :hyper_v)
    assert_equal("", SubutaiConfig.get_latest_id_artifact("subutai", "vagrant-subutai-stretch-hyperv.box"))

    SubutaiConfig.cleanup!

    SubutaiConfig.url_of_cdn = 'https://cdn.subutai.io:8338/kurjun/rest/invalid'
    assert_equal('https://cdn.subutai.io:8338/kurjun/rest/invalid', SubutaiConfig.url_of_cdn)

    SubutaiConfig.load_config("up", :virtualbox)
    SubutaiConfig.url_of_cdn = 'https://cdn.subutai.io:8338/kurjun/rest/invalid'
    assert_equal("", SubutaiConfig.get_latest_id_artifact("subutai", "vagrant-subutai-stretch-virtualbox-master.box"))
  end

  def test_get
    SubutaiConfig.load_config("up", :virtualbox)

    assert_equal(nil, SubutaiConfig.get(:INVALID_KEY))
  end

  def test_set_scope
    assert_raise do
      SubutaiConfig.set_scope(:SUBUTAI_SCOPE, "public_incorrect")
    end

    assert_nothing_raised do
      SubutaiConfig.set_scope(:SUBUTAI_SCOPE, 'PubLiC'.to_sym)
      SubutaiConfig.set_scope(:SUBUTAI_SCOPE, 'PriVate'.to_sym)
    end
  end

  def test_write
    SubutaiConfig.load_config("up", :libvirt)
    assert_true(SubutaiConfig.write?)
    SubutaiConfig.cleanup!

    SubutaiConfig.load_config("destroy", :virtualbox)
    assert_false(SubutaiConfig.write?)
  end

  def test_reload
    SubutaiConfig.load_config("reload", :virtualbox)
    assert_true(SubutaiConfig.reload?)

    SubutaiConfig.cleanup!
    SubutaiConfig.load_config("up", :libvirt)
    assert_false(SubutaiConfig.reload?)
  end

  def test_delete
    SubutaiConfig.load_config("destroy", :vmware)
    assert_true(SubutaiConfig.delete?)

    SubutaiConfig.cleanup!

    SubutaiConfig.load_config("up", :vmware)
    assert_false(SubutaiConfig.delete?)
  end

  def test_read
    SubutaiConfig.load_config("up", :vmware)
    assert_false(SubutaiConfig.read?)

    SubutaiConfig.cleanup!

    SubutaiConfig.load_config("provision", :vmware)
    assert_true(SubutaiConfig.read?)
  end

  def test_conf_file
    puts "conf file: #{SubutaiConfig::CONF_FILE}"
    assert_equal(SubutaiConfig::CONF_FILE, SubutaiConfig.conf_file)
    SubutaiConfig.override_conf_file "./test/vagrant-subutai-disk-withoutpath.yml"
    assert_equal("./test/vagrant-subutai-disk-withoutpath.yml", SubutaiConfig.conf_file)
  end

  def test_provider
    SubutaiConfig.load_config('up', :hyper_v)
    assert_equal(:hyper_v, SubutaiConfig.provider)

    SubutaiConfig.reset
    assert_equal(nil, SubutaiConfig.provider)
  end
end
