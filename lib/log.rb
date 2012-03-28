require 'logger'

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
  end

  def log_info type, &msg
    return unless @types[type.to_sym]
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
