$log ||= Logger.new($stderr).tap do |logger|
  logger.formatter = ->(severity, datetime, progname, msg) do
    "[#{datetime.to_ymd} #{datetime.to_hms}] #{severity} #{msg}\n"
  end
end
