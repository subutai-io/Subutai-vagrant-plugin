require 'test/unit'
require_relative '../lib/vagrant-subutai/packer/subutai_disk'
require_relative '../lib/vagrant-subutai/packer/subutai_config'


# Tests the subutai_net module
class SubutaDiskTest < Test::Unit::TestCase
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_global_variables
    assert_equal("SubutaiDisk", SubutaiDisk::DISK_NAME)
    assert_equal("vdi", SubutaiDisk::DISK_FORMAT)
    assert_equal("vdi", SubutaiDisk::DISK_FORMAT_VIRTUALBOX)
    assert_equal("vmdk", SubutaiDisk::DISK_FORMAT_VMWARE)
    assert_equal("vhdx", SubutaiDisk::DISK_FORMAT_HYPERV)
    assert_equal("qcow2", SubutaiDisk::DISK_FORMAT_LIBVIRT)
    assert_equal("vmware", SubutaiDisk::PROVIDER_VMWARE)
    assert_equal("hyper_v", SubutaiDisk::PROVIDER_HYPERV)
    assert_equal("libvirt", SubutaiDisk::PROVIDER_LIBVIRT)
  end

  def test_size
    assert_equal(12288, SubutaiDisk.size(10))
  end

  def test_libvirt_size
    assert_equal("26G", SubutaiDisk.libvirt_size(24))
  end

  def test_vmware_size
    assert_equal(22, SubutaiDisk.vmware_size(20))
  end

  def test_has_grow
   # SubutaiConfig.load_config("up", :virtualbox)
    SubutaiConfig.load_config("up", :virtualbox)
    SubutaiConfig.load_config_file('./test/disk_size.yml')
    has_grow, grow_by = SubutaiDisk.has_grow
    assert_true(true, has_grow)
    assert_equal(150, grow_by)
    assert_equal(1, SubutaiDisk.port)
  end

  def test_file

  end
end
