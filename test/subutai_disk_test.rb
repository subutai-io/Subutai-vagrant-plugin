require_relative '../lib/vagrant-subutai/packer/subutai_disk'
require_relative '../lib/vagrant-subutai/packer/subutai_config'
require 'rubygems'
require 'test/unit'
require 'fileutils'
# Tests the subutai_net module
class SubutaiDiskTest < Test::Unit::TestCase
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
    assert_equal("SubutaiDisk",
                 SubutaiDisk::DISK_NAME)
    assert_equal("vdi",
                 SubutaiDisk::DISK_FORMAT)
    assert_equal("vdi",
                 SubutaiDisk::DISK_FORMAT_VIRTUALBOX)
    assert_equal("vmdk",
                 SubutaiDisk::DISK_FORMAT_VMWARE)
    assert_equal("vhdx",
                 SubutaiDisk::DISK_FORMAT_HYPERV)
    assert_equal("qcow2",
                 SubutaiDisk::DISK_FORMAT_LIBVIRT)
    assert_equal("vmware",
                 SubutaiDisk::PROVIDER_VMWARE)
    assert_equal("hyper_v",
                 SubutaiDisk::PROVIDER_HYPERV)
    assert_equal("libvirt",
                 SubutaiDisk::PROVIDER_LIBVIRT)
    assert_equal('script/create_disk_and_attach.ps1',
                 SubutaiDisk::SCRIPT_HYPERV_DISK_CREATE_PATH)
  end

  def test_port
    SubutaiConfig.cleanup!
    SubutaiConfig.load_config('up', :virtualbox)
    assert_equal(1, SubutaiDisk.port)
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
    SubutaiConfig.override_conf_file('./test/disk_size.yml')
    SubutaiConfig.load_config("up", :virtualbox)
    has_grow, grow_by = SubutaiDisk.has_grow
    assert_true(true, has_grow)
    assert_equal(150, grow_by)
    assert_equal(1, SubutaiDisk.port)
  end

  def test_file
    assert_equal("./SubutaiDisk-1-250.vdi",
                 SubutaiDisk.file(250))

    SubutaiConfig.override_conf_file('./test/vagrant-subutai-disk-with-path.yml')
    SubutaiConfig.load_config('up', :virtualbox)

    assert_equal('/tmp/SubutaiDisk-1-389.vdi',
                 SubutaiDisk.file(SubutaiConfig.get_grow_by))
  end

  def test_file_path
    SubutaiConfig.cleanup!
    SubutaiConfig.override_conf_file('./test/vagrant-subutai-disk-withoutpath.yml')
    SubutaiConfig.load_config('up', :virtualbox)

    assert_equal(File.expand_path('SubutaiDisk-1-50.vdi'),
                 SubutaiDisk.file_path(SubutaiConfig.get_grow_by, "virtualbox"))
    assert_equal(File.expand_path('SubutaiDisk-1-50.vmdk'),
                 SubutaiDisk.file_path(SubutaiConfig.get_grow_by, "vmware"))
    assert_equal(File.expand_path('SubutaiDisk-1-50.vhdx'),
                 SubutaiDisk.file_path(SubutaiConfig.get_grow_by, "hyper_v"))
    assert_equal(File.expand_path('SubutaiDisk-1-50.qcow2'),
                 SubutaiDisk.file_path(SubutaiConfig.get_grow_by, "libvirt"))

    SubutaiConfig.cleanup!

    SubutaiConfig.override_conf_file('./test/vagrant-subutai-disk-with-path.yml')
    SubutaiConfig.load_config('up', :virtualbox)

    assert_equal(File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH), 'SubutaiDisk-1-389.vdi'),
                 SubutaiDisk.file_path(SubutaiConfig.get_grow_by, "virtualbox"))
    assert_equal(File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH), "SubutaiDisk-1-389.vmdk"),
                 SubutaiDisk.file_path(SubutaiConfig.get_grow_by, "vmware"))
    assert_equal(File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH), 'SubutaiDisk-1-389.vhdx'),
                 SubutaiDisk.file_path(SubutaiConfig.get_grow_by, "hyper_v"))
    assert_equal(File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH), 'SubutaiDisk-1-389.qcow2'),
                 SubutaiDisk.file_path(SubutaiConfig.get_grow_by, "libvirt"))

    SubutaiConfig.cleanup!
  end

  def test_safe_conf
    SubutaiConfig.cleanup!

    SubutaiConfig.override_conf_file('./test/vagrant-subutai-disk-with-path.yml')
    SubutaiConfig.load_config('up', :virtualbox)
    SubutaiDisk.save_conf(SubutaiConfig.get_grow_by)

    assert_equal(389, SubutaiConfig.get(:_DISK_SIZE))
    assert_equal(1, SubutaiConfig.get(:_DISK_PORT))
    assert_true(File.exist?('./.vagrant/generated.yml'))


    SubutaiConfig.override_conf_file('./test/vagrant-subutai-disk-grow.yml')
    SubutaiConfig.load_config('up', :virtualbox)
    SubutaiDisk.save_conf(SubutaiConfig.get_grow_by)

    assert_equal(400, SubutaiConfig.get(:_DISK_SIZE))
    assert_equal(2, SubutaiConfig.get(:_DISK_PORT))
    assert_true(File.exist?('./.vagrant/generated.yml'))
  end

  def test_vmware_create_disk
    if File.exist?('/tmp/SubutaiDisk-1-1.vmdk')
      FileUtils.rm('/tmp/SubutaiDisk-1-1.vmdk')
    end
    SubutaiConfig.cleanup!
    SubutaiConfig.override_conf_file('./test/disk_create.yml')
    SubutaiConfig.load_config('up', :virtualbox)

    puts "DISKSIZE: #{SubutaiConfig.get(:DISK_SIZE)}"
    assert_equal(1, SubutaiConfig.get_grow_by)
    assert_true(SubutaiDisk.vmware_create_disk(SubutaiConfig.get_grow_by,
                                               SubutaiDisk.file_path(SubutaiConfig.get_grow_by,
                                                                     "vmware")))
  end

  def test_hyperv_create_disk
    SubutaiConfig.cleanup!
    SubutaiConfig.override_conf_file('./test/disk_create.yml')
    SubutaiConfig.load_config('up', :virtualbox)

    assert_equal(1, SubutaiConfig.get_grow_by)
    assert_false(SubutaiDisk.hyperv_create_disk(SubutaiConfig.get_grow_by,
                                                SubutaiDisk.file_path(SubutaiConfig.get_grow_by,
                                                                      "hyper_v")))
  end

  def test_save_path
    SubutaiConfig.cleanup!
    SubutaiConfig.override_conf_file('./test/disk_create.yml')
    SubutaiConfig.load_config('up', :virtualbox)


    grow_by = SubutaiConfig.get_grow_by
    assert_equal(1, grow_by)
    assert_equal('/tmp/SubutaiDisk-1-1.vmdk',
                 SubutaiDisk.file_path(grow_by, "vmware"))

    File.delete(SubutaiDisk.file_path(grow_by, "vmware")) if File.exist?(SubutaiDisk.file_path(grow_by,
                                                                                               "vmware"))

    assert_true(SubutaiDisk.vmware_create_disk(grow_by,
                                               SubutaiDisk.file_path(grow_by,
                                                                     "vmware")))

    assert_true(SubutaiDisk.save_path(SubutaiDisk.port,
                          SubutaiDisk.file_path(grow_by,
                                                "vmware")))

    assert_true(SubutaiDisk.save_conf(grow_by))

    hash = {}
    hash[1] = "/tmp/SubutaiDisk-1-1.vmdk"
    assert_equal(hash, SubutaiConfig.get(:_DISK_PATHES))


    # Let's set disk size 150 Gb, grow by would be 49
    SubutaiConfig.put(:DISK_SIZE, 150, false)
    grow_by = SubutaiConfig.get_grow_by
    assert_equal(49, grow_by)
    assert_equal('/tmp/SubutaiDisk-2-49.vmdk',
                 SubutaiDisk.file_path(grow_by, "vmware"))

    File.delete(SubutaiDisk.file_path(grow_by, "vmware")) if File.exist?(SubutaiDisk.file_path(grow_by,
                                                                                               "vmware"))

    assert_true(SubutaiDisk.vmware_create_disk(grow_by,
                                               SubutaiDisk.file_path(grow_by,
                                                                     "vmware")))

    assert_true(SubutaiDisk.save_path(SubutaiDisk.port,
                                      SubutaiDisk.file_path(grow_by,
                                                            "vmware")))

    assert_true(SubutaiDisk.save_conf(grow_by))
    hash[2] = "/tmp/SubutaiDisk-2-49.vmdk"
    assert_equal(hash, SubutaiConfig.get(:_DISK_PATHES))

    SubutaiConfig.cleanup!
    assert_equal(nil, SubutaiConfig.get(:_DISK_PATHES))
  end
end
