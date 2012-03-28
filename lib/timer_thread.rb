require 'thread'
#require 'my_queue'

# Improvement: having a constant number of threads instead of one per timer
module TimerThread
  attr_reader :queue

  def init_timer_thread
    @queue = Queue.new
  end

  def add_timed_to_queue time, event
    self.add_timer(time) { process_event event }
  end

  def add_timer time, &block
    t = Thread.new do
      sleep time
      queue << TimerEvent.new(t, block)
    end
  end

  def process
    while true
      ev = queue.pop
      if ev.class == TimerEvent
        ev.thread.join
        ev.run
      else
        process_event ev
      end
    end
  end

  class TimerEvent
    def initialize t, b
      @b = b
      @t = t
    end

    def thread
      @t
    end

    def run
      @b.call
    end
  end
end
