require 'rake_compiler_dock'
require 'test/unit'
begin
  require 'test/unit/notify'
rescue LoadError
end

class TestStarter < Test::Unit::TestCase
  include RakeCompilerDock

  def test_make_valid_user_name
    assert_equal "mouse-click", Starter.make_valid_user_name("Mouse-Click")
    assert_equal "very_very_very_l-ame_with_spaces", Starter.make_valid_user_name("Very very very long name with spaces")
    assert_equal "_nobody", Starter.make_valid_user_name("nobody")
    assert_equal "_rvm", Starter.make_valid_user_name("rvm")
    assert_equal "staff", Starter.make_valid_user_name("staff")
    assert_equal "a", Starter.make_valid_user_name("a")
    assert_equal "_", Starter.make_valid_user_name("")
    assert_equal "_", Starter.make_valid_user_name(nil)
  end

  def test_make_valid_group_name
    assert_equal "mouse-click", Starter.make_valid_group_name("Mouse-Click")
    assert_equal "very_very_very_l-ame_with_spaces", Starter.make_valid_group_name("Very very very long name with spaces")
    assert_equal "nobody", Starter.make_valid_group_name("nobody")
    assert_equal "_rvm", Starter.make_valid_group_name("rvm")
    assert_equal "_staff", Starter.make_valid_group_name("staff")
    assert_equal "a", Starter.make_valid_group_name("a")
    assert_equal "_", Starter.make_valid_group_name("")
    assert_equal "_", Starter.make_valid_group_name(nil)
  end

end
