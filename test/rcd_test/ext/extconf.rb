require "mkmf"

include RbConfig

puts "-"*70
puts "CONFIG['arch']: #{CONFIG['arch'].inspect}"
puts "CONFIG['sitearch']: #{CONFIG['sitearch'].inspect}"
puts "CONFIG['RUBY_SO_NAME']: #{CONFIG['RUBY_SO_NAME'].inspect}"
puts "RUBY_PLATFORM: #{RUBY_PLATFORM.inspect}"
puts "Gem::Platform.local.to_s: #{Gem::Platform.local.to_s.inspect}"
puts "-"*70

create_makefile("rcd_test_ext")
