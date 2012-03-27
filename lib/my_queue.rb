require 'thread'

class MyQueue
  def initialize
    @queue = []
    @mutex = Mutex.new
    @condvar = ConditionVariable.new
  end

  def pop
    @mutex.synchronize do
      while true
        return @queue.pop unless @queue.empty?
        @condvar.wait @mutex
      end
    end
  end

  def push e
    @mutex.synchronize do
      @queue << e
      @condvar.signal
    end
  end

  alias << push
end
