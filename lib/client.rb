require 'events'

module ClientData
  def add_file_part id, part
    @files[id] ||= Set.new
    @files[id] << part
    @remaining_size -= 1
  end
end

class Client
  attr_reader :id, :settings, :thread, :files
  attr_accessor :remaining_size

  include TimerThread
  include ClientData

  def initialize id, settings, server
    init_timer_thread
    @id = id
    @settings = settings
    @server = server
    @remaining_size = @settings.generate_client_storage
    @files = {}
  end

  def timer_generator
    @settings
  end

  def setup
    ClientEvent.events.each do |event|
      add_timer_from_generator(event::GENERATE) do
        @server.queue << event.new(*@settings.send("generate_#{event::GENERATE}_args".to_sym))
      end
    end
  end

  def run
    @thread = Thread.new do
      setup
      process
    end
  end

  def process_event event
    event.run self
  end

  class RunClientEvent
    def initialize name, args
      @name, @args = name, args
    end

    def run client
      client.send @name, *@args
    end
  end
end

class ClientInfo
  attr_reader :client

  include ClientData

  def initialize client
    @client = client
    @files = {}
    @remaining_size = client.remaining_size
  end

  def id
    @client.id
  end

  def settings
    @client.settings
  end

  def has_file_part? id, part
    @files[id] && @files[id].include?(part)
  end

  def is_full?
    @remaining_size == 0
  end

  def send_client_event name, args
    self.send(name, *args)
    client.queue << Client::RunClientEvent.new(name, args)
  end
end
