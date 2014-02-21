module CloudstackNagios
  module Helper
    RETURN_CODES = {0 => 'ok', 1 => 'warning', 2 => 'critical'}
    
    def load_template(template_path)
      if File.file?(template_path)
        templ = Erubis::Eruby.new(File.read template_path)
        templ.filename = template_path
        return templ
      else
        say "Error: template not found #{template_path}"
        exit 1
      end
    end

    def cs_routers
      routers = client.list_routers(status: 'Running')
      routers += client.list_routers(projectid: -1, status: 'Running')
    end

    def exit_with_failure(exception)
      say 'ERROR: command execution failed!', :red
      say "Message: ", :magenta
      say exception.message
      say "Backtrace:", :magenta
      say exception.backtrace
      exit 3
    end

    def check_data(total, usage, warning, critical)
      usage_percent = 100.0 / total.to_f * usage.to_f
      code = 3
      if usage_percent < warning
        code = 0
      elsif usage_percent < critical
        code = 1
      else 
        code = 2
        usage_percent = 0
      end
      [code, usage_percent.round(0)]
    end
  end
end
