class Mechanize::Download

  # @!visibility private
  def content_hash
    @content_hash ||= Digest::SHA1.new.io(self.body_io).hexdigest
  end

end
