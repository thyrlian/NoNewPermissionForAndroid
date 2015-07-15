#!/usr/bin/env ruby

require 'json'

module NoNewPermission
  class Permission
    attr_reader :name
    
    def initialize(name)
      @name = name
    end
    
    def ==(o)
      self.class == o.class && @name == o.name
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
  
  class Reader
    class << self
      def synthesize_command
        android_build_tools_path = ARGV[0]
        apk_file = ARGV[1]
        "#{android_build_tools_path}/aapt d permissions #{apk_file}"
      end
      
      def parse_output(&blk)
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
    end
    
    private_class_method :synthesize_command
  end
  
  class Monitor
    class << self
      def get_permissions
        permissions = []
        Reader.parse_output do |permission|
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
      
      def take_snapshot
        
      end
    end
    
    private_class_method :get_permissions
  end
end