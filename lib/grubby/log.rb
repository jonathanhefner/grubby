$log ||= Logger.new($stderr).tap do |logger|
  logger.formatter = ->(severity, time, progname, msg) do
    "[#{time.strftime "%Y-%m-%d %H:%M:%S"}] #{severity} #{msg}\n"
  end
end
