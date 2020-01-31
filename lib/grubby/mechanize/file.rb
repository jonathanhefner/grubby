# @!visibility private
class Mechanize::File

  def self.read_local(path)
    uri_path = File.expand_path(path).gsub(%r"[^/\\]+"){|component| CGI.escape(component) }
    self.new(URI::File.build(path: uri_path), nil, File.read(path), "200")
  end

  def content_hash
    @content_hash ||= self.body.to_s.sha1
  end

end
