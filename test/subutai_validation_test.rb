require 'test/unit'
require_relative '../lib/vagrant-subutai/packer/subutai_validation'
require_relative '../lib/vagrant-subutai/packer/subutai_config'

# Tests the subutai_hooks module
class SubutaiValidationTest < Test::Unit::TestCase
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test_bool
    assert_true(SubutaiValidation.bool?('true'))
    assert_false(SubutaiValidation.bool?('not_fool'))
    assert_true(SubutaiValidation.bool?('false'))
    assert_true(SubutaiValidation.bool?(true))
    assert_true(SubutaiValidation.bool?(false))
  end

  def test_is_json
    assert_true(SubutaiValidation.is_json?("{\"key\": \"value\"}"))
    assert_false(SubutaiValidation.is_json?("{key: value}"))
    assert_false(SubutaiValidation.is_json?("key value"))
    assert_true(SubutaiValidation.is_json?({"key": "value"}))
    assert_true(SubutaiValidation.is_json?('{"key": "value"}'))
  end

  def test_validation
    assert_true(SubutaiValidation.validate(:AUTHORIZED_KEYS, './test/'))
    assert_true(SubutaiValidation.validate(:DISK_SIZE, 1000))
    assert_true(SubutaiValidation.validate(:LIBVIRT_NO_MACVTAP, 'false'))
    assert_true(SubutaiValidation.validate(:SUBUTAI_ENV, 'sysnet'))
    assert_true(SubutaiValidation.validate(:APT_PROXY_URL, 'https://google.com'))
    assert_true(SubutaiValidation.validate(:SUBUTAI_SCOPE, 'PublIC'))

    assert_raise do
      SubutaiValidation.validate(:DISK_SIZE, 'fdfd')
    end

    assert_raise do
      SubutaiValidation.validate(:SUBUTAI_ENV_TYPE, 'bazaaar')
    end

    assert_raise do
      SubutaiValidation.validate(:SUBUTAI_SCOPE, 'private1')
    end

    assert_raise do
      SubutaiValidation.validate(:SUBUTAI_SCOPE, 'private1')
    end

    assert_raise do
      SubutaiValidation.validate(:SUBUTAI_MAN_TMPL, 'private1')
    end

    assert_raise do
      SubutaiValidation.validate(:SUBUTAI_PASSWORD, 56565)
    end
  end

  def test_user_conf_params
    SubutaiValidation::USER_CONF_PARAMS_TYPE.keys.each do |key|
      assert_true(SubutaiConfig::USER_PARAMETERS.include?(key))
    end
  end

  def test_user_conf_params_type
    user_conf_types = [:int, :bool, :path, :url, :string, :enum, :json_object]

    SubutaiValidation::USER_CONF_PARAMS_TYPE.keys.each do |key|
      assert_true(user_conf_types.include?(SubutaiValidation::USER_CONF_PARAMS_TYPE[key]))
    end
  end

  def test_writable_and_exist
    assert_false(SubutaiValidation.writable_and_exist?('/home'))
    assert_true(SubutaiValidation.writable_and_exist?("#{Dir.pwd}"))
    assert_false(SubutaiValidation.writable_and_exist?('/root'))

    assert_false(SubutaiValidation.writable_and_exist?('/home/not_exist_user'))
  end
end