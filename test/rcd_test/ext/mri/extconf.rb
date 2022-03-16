if RUBY_ENGINE == "jruby"
  File.open("Makefile", "w") do |mf|
    mf.puts "# Dummy makefile for JRuby"
    mf.puts "all install::\n"
  end
else
  require "mkmf"

  include RbConfig

  puts "-"*70
  puts "CONFIG['arch']: #{CONFIG['arch'].inspect}"
  puts "CONFIG['sitearch']: #{CONFIG['sitearch'].inspect}"
  puts "CONFIG['RUBY_SO_NAME']: #{CONFIG['RUBY_SO_NAME'].inspect}"
  puts "RUBY_PLATFORM: #{RUBY_PLATFORM.inspect}"
  puts "Gem::Platform.local.to_s: #{Gem::Platform.local.to_s.inspect}"
  puts "-"*70

  have_func('rb_thread_call_without_gvl', 'ruby/thread.h') ||
      raise("rb_thread_call_without_gvl() not found")

  create_makefile("rcd_test/rcd_test_ext")
end
