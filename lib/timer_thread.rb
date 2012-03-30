require 'thread'

class TimerManager
  def initialize
    @timers = []
    @condvar = ConditionVariable.new
    @mutex = Mutex.new
    @thread = Thread.new do
      @mutex.synchronize do
        while true
          old = Time.now
          @condvar.wait(@mutex, min_time)
          new = Time.now
          @timers.each { |t| t.time -= new - old }
          @timers.reject! do |t|
            unless t.time > 0.0
              t.block.call
            end
            t.time < 0.0
          end
        end
      end
    end
  end

  def min_time
    return 1000 if @timers.empty?
    @timers.min_by { |t| t.time }.time
  end

  def add_timer t, &block
    @mutex.synchronize do
      @timers << TimerInfo.new(t, block)
    end
    @condvar.signal
  end

  class TimerInfo
    attr_accessor :time, :block

    def initialize time, block
      @time, @block = time, block
    end
  end
end

# Improvement: having a constant number of threads instead of one per timer
module TimerThread
  attr_reader :queue

  def init_timer_thread
    @queue = Queue.new
  end

  def add_timer_from_generator gen_name, &block
    next_iteration = Proc.new do
      block.call
      add_timer timer_generator.send("generate_next_#{gen_name}_time".to_sym), &next_iteration
    end
    add_timer timer_generator.send("generate_next_#{gen_name}_time".to_sym), &next_iteration
  end

  def add_timed_to_queue time, event
    self.add_timer(time) { process_event event }
  end

  def add_timer time, &block
    return if time < 0 || time.to_f.infinite?
    @@timerthread ||= TimerManager.new
    @@timerthread.add_timer time do
      queue << TimerEvent.new(block)
    end
  end

  def process
    while true
      ev = queue.pop
      if ev.class == TimerEvent
        ev.run
      else
        process_event ev
      end
    end
  end

  class TimerEvent
    def initialize b
      @b = b
    end

    def run
      @b.call
    end
  end
end
