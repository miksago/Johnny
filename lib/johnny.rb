require "rubygems"
require "erb"
require "fssm"
require "rdiscount"

class Johnny
  def initialize(dir=Dir.pwd)
    @source = File.expand_path(dir)
    @destination = File.join(@source, "html")
    
    @template = ERB.new(File.read(File.expand_path(File.join(File.dirname(__FILE__), "..", "templates", "default.html.erb"))))
    
    unless File.exists?(@destination) && File.directory?(@destination)
      Dir.mkdir(@destination)
    end
  end
  
  def handle(action, path)
    if [".md", ".mdown", ".markdown"].include?(File.extname(path))
      source = File.join(@source, path)
      target = File.join(@destination, "#{File.basename(path, File.extname(path))}.html")
      action = "handle_#{action}"
      
      if self.respond_to?(action)
        self.send(action, source, target)
      end
    end
  end
  
  
  def handle_create(source, target)
    parse(source, target)
    puts "Create: #{target}"
    
    return true
  end
  
  def handle_update(source, target)
    parse(source, target)
    puts "Update: #{target}"
    
    return true
  end
  
  def handle_delete(source, target)
    if File.exists?(target)
      puts "Deleted: #{target}"
      File.delete(target)
    end
  end
  
  def run!
    # this is something I'd expect in javascript, not ruby.
    johnny = self
    
    puts "Watching directory for changes to files..."
    puts "-> Parsed files will be placed in: #{File.join(Dir.pwd, "html")}"
    
    FSSM.monitor(@source, "**/*.*") do
      update {|base, relative| johnny.handle("update", relative) }
      delete {|base, relative| johnny.handle("delete", relative) }
      create {|base, relative| johnny.handle("create", relative) }
    end
    
    return
  end
  
  def parse(source, target)
    File.open("#{target}", "w+") {|f|
      f.write(@template.result(ERBTemplate.new(
        File.basename(source, File.extname(source)),
        RDiscount.new(File.read(source)).to_html
      ).getBinding))
    }
    
    return nil
  end
end

class ERBTemplate
  def initialize(title, content)
    @title = title
    @content = content
  end
  
  def getBinding
    return binding()
  end
end