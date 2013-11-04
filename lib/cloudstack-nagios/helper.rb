module CloudstackNagios
  module Helper
    def template(name)
      template = File.read(File.join(File.dirname(__FILE__), "templates", name))
      Erubis::Eruby.new(template)
    end
  end
end
