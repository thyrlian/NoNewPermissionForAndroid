#!/usr/bin/env ruby

require 'json'
require 'open3'

module NoNewPermission
  PASS                = 0
  FAIL                = 1
  PASS_WITH_ATTENTION = 2
  
  DELIMITER = '=' * 70
  
  class Permission
    attr_reader :name
    
    def initialize(name)
      @name = name
    end
    
    def eql?(other)
      self.class == other.class && @name == other.name
    end
    
    def hash
      @name.hash ^ self.class.hash
    end
    
    def ==(other)
      eql?(other)
    end
    
    def <=>(other)
      @name <=> other.name
    end
    
    def to_json(*args)
      {
        'json_class' => self.class.name,
        'data' => @name
      }.to_json(*args)
    end
    
    class << self
      def json_create(object)
        new(object['data'])
      end
    end
  end
  
  class Detector
    attr_reader :android_build_tools_path, :apk_file
    
    def initialize(android_build_tools_path, apk_file)
      @android_build_tools_path = android_build_tools_path
      @apk_file = apk_file
    end
    
    def synthesize_command
      "#{@android_build_tools_path.gsub(/\/$/, '')}/aapt d permissions #{@apk_file}"
    end
    
    def parse_raw_permissions(&blk)
      regex_permission = /(uses-)?permission:\s.*?(([^'\s\.]+\.)+[^'\s\.]+)/
      begin
        stdin, stdout, stderr, wait_thr = Open3.popen3(synthesize_command)
        stdout.each_line do |line|
          regex_permission.match(line)
          if $~
            blk.call(Permission.new($~[2]))
          end
        end
      rescue Exception => e
        puts DELIMITER
        puts e.message
        puts e.backtrace
        puts DELIMITER
        exit 1
      ensure
        exit_status = wait_thr.value
        unless exit_status.success?
          puts DELIMITER
          if exit_status.signaled?
            termsig = exit_status.termsig || "Null"
            puts "Terminated because of an uncaught signal: #{termsig}"
          else
            stderr.each_line do |line|
              puts line
            end
          end
          puts DELIMITER
          [stdin, stdout, stderr].each {|io| io.close}
          exit 1
        end
      end
    end
    
    def get_permissions
      permissions = []
      parse_raw_permissions do |permission|
        permissions.push(permission) unless permissions.include?(permission)
      end
      permissions
    end
    
    private :synthesize_command, :parse_raw_permissions
  end
  
  class Serializer
    class << self
      def parse(snapshot_file)
        begin
          File.open(snapshot_file, 'r') do |file|
            JSON.load(file)
          end
        rescue Errno::ENOENT => e
          puts DELIMITER
          puts 'Snapshot file does not exist, please generate one manually.'
          puts DELIMITER
          exit 1
        end
      end
      
      def generate(permissions, snapshot_file)
        File.open(snapshot_file, 'w') do |file|
          file.puts(permissions.to_json)
        end
      end
    end
  end
  
  class Comparator
    attr_reader :old_permissions, :new_permissions
    
    def initialize(old_permissions, new_permissions)
      @old_permissions = old_permissions
      @new_permissions = new_permissions
    end
    
    def get_less
      @old_permissions - @new_permissions
    end
    
    def get_more
      @new_permissions - @old_permissions
    end
  end
  
  class Inspector
    class << self
      def check(comparator)
        more = comparator.get_more
        less = comparator.get_less
        if more.size > 0
          return [FAIL, more, less]
        elsif less.size > 0
          return [PASS_WITH_ATTENTION, [], less]
        else
          return [PASS, [], []]
        end
      end
    end
  end
  
  class Handler
    class << self
      def deal(result, action_pass, action_fail, action_attention)
        case result.first
        when PASS
          action_pass.call unless action_pass.nil?
          exit 0
        when FAIL
          action_fail.call(result[1], result[2])
          exit 1
        when PASS_WITH_ATTENTION
          action_attention.call(result[2])
          exit 0
        end
      end
    end
  end
  
  class Main
    attr_reader :android_build_tools_path, :apk_file, :snapshot_file, :permissions
    
    def initialize(android_build_tools_path, apk_file)
      @android_build_tools_path = android_build_tools_path
      @apk_file = apk_file
      @snapshot_file = "#{File.expand_path(File.dirname(__FILE__))}/permissions_snapshot.json"
      @permissions = Detector.new(@android_build_tools_path, @apk_file).get_permissions
    end
    
    def take_snapshot
      if File.exists?(@snapshot_file)
        message = 'Snapshot file has been updated.'
      else
        message = 'Snapshot file has been generated.'
      end
      Serializer.generate(@permissions, @snapshot_file)
      puts message
    end
    
    def run
      comparator = Comparator.new(Serializer.parse(@snapshot_file), @permissions)
      result = Inspector.check(comparator)
      Handler.deal(
        result,
        Proc.new do
          puts DELIMITER
          puts 'No permission is changed.'
          puts DELIMITER
        end,
        Proc.new do |more, less|
          puts DELIMITER
          puts "#{more.size} new #{more.size == 1 ? 'permission' : 'permissions'} added:"
          more.each do |permission|
            puts "#{"\s" * 4}#{permission.name}"
          end
          unless less.empty?
            puts ''
            puts "#{less.size} old #{less.size == 1 ? 'permission' : 'permissions'} removed:"
            less.each do |permission|
              puts "#{"\s" * 4}#{permission.name}"
            end
          end
          puts DELIMITER
        end,
        Proc.new do |less|
          puts DELIMITER
          puts "Brilliant!  You got #{less.size} #{less.size == 1 ? 'permission' : 'permissions'} removed:"
          less.each do |permission|
            puts "#{"\s" * 4}#{permission.name}"
          end
          puts ''
          take_snapshot
          puts DELIMITER
        end
      )
    end
  end
end