#!/usr/bin/env ruby

require 'json'

module NoNewPermission
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
    
    def <=>(anOther)
      @name <=> anOther.name
    end
    
    def to_json(*args)
      {
        'json_class' => self.class.name,
        'data' => [@name]
      }.to_json(*args)
    end
    
    class << self
      def json_create(object)
        new(*object['data'])
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
      "#{@android_build_tools_path}/aapt d permissions #{@apk_file}"
    end
    
    def parse_raw_permissions(&blk)
      regex_permission = /(uses-)?permission:\s.*?(([^'\s\.]+\.)+[^'\s\.]+)/
      begin
        output = IO.popen(synthesize_command)
        output.each_line do |line|
          regex_permission.match(line)
          if $~
            blk.call(Permission.new($~[2]))
          end
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
    
    def get_permissions
      permissions = []
      parse_raw_permissions do |permission|
        permissions.push(permission) unless permissions.include?(permission)
      end
      permissions
    end
    
    def list_permissions
      permissions = get_permissions
      permissions.sort.each do |permission|
        puts permission.name
      end
      puts "Total: #{permissions.size}"
    end
    
    private :synthesize_command, :parse_raw_permissions
  end
  
  class Serializer
    class << self
      def parse(snapshot_file)
        File.open(snapshot_file, 'r') do |file|
          JSON.load(file)
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
  
  class Main
    class << self
      def run
        android_build_tools_path = ARGV[0]
        apk_file = ARGV[1]
        snapshot_file = 'permissions_snapshot.json'
        detector = Detector.new(android_build_tools_path, apk_file)
        Serializer.generate(detector.get_permissions, snapshot_file)
        Serializer.parse(snapshot_file).each do |permission|
          puts permission.name
        end
      end
    end
  end
end

NoNewPermission::Main.run