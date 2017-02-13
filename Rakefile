$:.unshift File.expand_path('..', __FILE__)
require 'no_new_permission'

include NoNewPermission

desc 'Generate the reference snapshot file, before the first run'
task :take_snapshot, [:android_home, :apk_file] do |t, args|
  raise(RuntimeError, 'Argument can not be null') unless args[:android_home] && args[:apk_file]
  android_build_tools_path = `ls -d #{args[:android_home]}/build-tools/*/ | tail -1`.chomp
  Main.new(android_build_tools_path, args[:apk_file]).take_snapshot
end

desc 'Examine the apk and the snapshot to compare the permission change'
task :examine, [:android_home, :apk_file] do |t, args|
  raise(RuntimeError, 'Argument can not be null') unless args[:android_home] && args[:apk_file]
  android_build_tools_path = `ls -d #{args[:android_home]}/build-tools/*/ | tail -1`.chomp
  Main.new(android_build_tools_path, args[:apk_file]).run
end

task :default => :examine