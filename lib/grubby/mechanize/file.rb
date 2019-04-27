class Mechanize::File

  # @!visibility private
  def content_hash
    @content_hash ||= self.body.to_s.sha1
  end

end
