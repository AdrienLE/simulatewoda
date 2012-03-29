require 'logger'
require 'colorize'

# colorize doesn't implement this one for some reason...
String.class_eval do
  def bold
    if self =~ /^\e\[\d+;(\d+);(\d+)m(.*)\e\[0m$/
      "\e[1;#{$1};#{$2}m#{$3}\e[0m"
    else
      "\e[1;39;49m#{self}\e[0m"
    end
  end
end

# TODO: Set the various log types through the command line arguments
# TODO: Handle messages not in blocks

# There is a general norm: before the definition of a function utilizing a custom log type,
# call LOG.{show,hide}_name_of_type, so that the type is registered (call use show or hide
# according to whether it should be shown or hidden by default)
class Log < Logger
  attr_reader :types

  def initialize
    super STDOUT
    @types = {}

    old_formatter = self.formatter
    self.formatter = Proc.new { |severity, time, progname, msg|
#      return old_formatter.call severity, time, progname, msg unless severity == Logger::INFO
      msg_str = msg.class == Proc ? msg.call.to_s : msg.to_s
      time_str = time.strftime "%x %X"
      type_str = @current_type.to_s
      if @logdev.dev.tty?
        type_str = type_str.blue.bold
        time_str = time_str.light_yellow
      end
      "[#{time_str}] #{type_str}: #{msg_str}\n"
    }
  end

  def log_info type, &msg
    return unless @types[type.to_sym]
    @current_type = type
    self.info &msg
  end

  def method_missing method, *args, &block
    if method.to_s =~ /^log_(.*)$/
      log_info $1.to_sym, &block
    elsif method.to_s =~ /^show_(.*)$/
      @types[$1.to_sym] = true
    elsif method.to_s =~ /^hide_(.*)$/
      @types[$1.to_sym] = false
    else
      super
    end
  end
end

LOG = Log.new
LOG.level = Logger::DEBUG if $DEBUG
