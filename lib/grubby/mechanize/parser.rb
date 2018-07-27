require "fileutils"

module Mechanize::Parser

  # Saves the payload to a specified directory, but using the default
  # filename suggested by the server.  If a file with that name already
  # exists, this method will try to find a free filename by appending
  # numbers to the original name.  Returns the full path of the saved
  # file.
  #
  # NOTE: this method expects a +#save!+ method to be defined by the
  # class extending +Mechanize::Parser+, e.g. +Mechanize::File#save!+
  # and +Mechanize::Download#save!+.
  #
  # @param directory [String]
  # @return [String]
  def save_to(directory)
    raise "#{self.class}#save! is not defined" unless self.respond_to?(:save!)

    FileUtils.mkdir_p(directory)
    path = find_free_name(File.join(directory, @filename))
    save!(path)
    path
  end

  # Saves the payload to a specified directory, but using the default
  # filename suggested by the server.  If a file with that name already
  # exists, that file will be overwritten.  Returns the full path of the
  # saved file.
  #
  # NOTE: this method expects a +#save!+ method to be defined by the
  # class extending +Mechanize::Parser+, e.g. +Mechanize::File#save!+
  # and +Mechanize::Download#save!+.
  #
  # @param directory [String]
  # @return [String]
  def save_to!(directory)
    raise "#{self.class}#save! is not defined" unless self.respond_to?(:save!)

    FileUtils.mkdir_p(directory)
    path = File.join(directory, @filename)
    save!(path)
    path
  end

end
