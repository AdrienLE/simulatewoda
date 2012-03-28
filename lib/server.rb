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

  def timer_generator
    @settings
  end

  def setup
    start_nb = @settings.start_nb_clients
    puts "Spawning an initial number of #{start_nb} client#{start_nb > 1 ? 's' : ''}"
    start_nb.times do |i|
      c = Client.new i, @settings, self
      @clients << c
      @client_infos << ClientInfo.new(c)
    end
    @clients.each { |c| c.run }

    add_timer_from_generator(:spawn_clients) do
      to_spawn = @settings.generate_nb_clients_to_spawn
      puts "Spawning #{to_spawn} new client#{start_nb > 1 ? 's' : ''}"
      to_spawn.times do
        c = Client.new @clients.size, @settings, self
        @clients << c
        @client_infos << ClientInfo.new(c)
        c.run
      end
    end
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
    if client
      client.add_file_part id, part
      puts "Adding part #{part} of file #{id} to client #{client.id}"
    else
      puts "Network is full"
    end
  end

  def add_file file
    file.parts.each do |p|
      put_file_part file.id, p
    end
    file.codes.each do |p|
      put_file_part file.id, p
    end
  end
end
