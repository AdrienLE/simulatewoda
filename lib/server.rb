require 'timer_thread'
require 'client'

class Server
  include TimerThread

  attr_reader :clients, :client_infos

  def initialize settings
    init_timer_thread
    @settings = settings
    @clients = []
    @client_infos = []
  end

  def setup
    @settings.nb_clients.times do |i|
      c = Client.new i, @settings
      @clients << c
      @client_infos << ClientInfo.new(c)
    end
    @clients.each { |c| c.run }
  end

  def run
    setup
    process
  end

  def process_event event
    event.run self
  end

  def put_file_part id, part
    client = @client_infos.select { |c| !c.is_full? && !c.has_file_part?(id, part) }.sample
    client.add_file_part id, part
  end

  def add_file file
    file.parts.each do |p|
      put_file_part file.id, p
    end
    file.codes.each do |p|
      put_file_part file.id, p
    end
  end

  class AddFileEvent
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
end
