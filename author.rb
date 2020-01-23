# author.rb

Author = Struct.new(:name, :email, :time) do
  def to_s
    timestamp = time.strftime("%s %Z")
    "#{ name } <#{ email }> #{ timestamp }"
  end
end
