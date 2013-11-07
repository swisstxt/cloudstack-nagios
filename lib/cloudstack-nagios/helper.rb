module CloudstackNagios
  module Helper
    def load_template(name)
      templ = File.read(File.join(File.dirname(__FILE__), "templates", name))
      Erubis::Eruby.new(templ)
    end

    def routers
      routers = client.list_routers
      routers += client.list_routers(projectid: -1)
    end
  end
end
