require 'wfile'

class ClientEvent
  def self.inherited klass
    (@klasses ||= []) << klass
  end
  
  def self.events
    @klasses
  end
end

class AddFileEvent < ClientEvent
  GENERATE = :add_file

  def initialize parts, codes
    @parts, @codes = parts, codes
  end
  
  def run server
    file = WFile.new @parts, @codes
    server.add_file file
  end
end

class RemoveFileEvent
end

class GetFileEvent
end

class ClientDieEvent
end

class ClientDownEvent
end

class ClientUpEvent
end

# TODO: Handle corruption
