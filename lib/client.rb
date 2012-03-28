require 'events'

class Client
  attr_reader :id, :settings, :thread, :files
  attr_accessor :remaining_size

  include TimerThread

  def initialize id, settings, server
    init_timer_thread
    @id = id
    @settings = settings
    @server = server
    @remaining_size = @settings.generate_client_storage
    @files = {}
  end

  def setup
    ClientEvent.events.each do |event|
      next_iteration = Proc.new do
        @server.queue << event.new(*@settings.send("generate_#{event::GENERATE}_args".to_sym))
        add_timer @settings.send("generate_next_#{event::GENERATE}_time".to_sym), &next_iteration
      end
      add_timer @settings.send("generate_next_#{event::GENERATE}_time".to_sym), &next_iteration
#      @server.add_timed_to_queue @settings.send("generate_next_#{event::GENERATE}_time".to_sym),
#                                 event.new(*@settings.send("generate_#{event::GENERATE}_args".to_sym))
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

  class AddFilePartEvent
    def initialize id, part
      @id, @part = id, part
    end

    def run client
      client.files[@id] ||= Set.new
      client.files[@id] << @part
      client.remaining_size -= 1
    end
  end
end

class ClientInfo
  attr_reader :client

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

  def add_file_part id, part
    @files[id] ||= Set.new
    @files[id] << part
    @remaining_size -= 1
    client.queue << Client::AddFilePartEvent.new(id, part)
  end
end
