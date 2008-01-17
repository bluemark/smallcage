module SmallCage
  module MenuHelper
    
    def menu_active(name)
      p = @obj["menu_path"]
      p ||= uri
      return p =~ %r{^/#{name}/} ? "active" : "inactive"
    end
    
    def menu_active_rex(rex)
      p = @obj["menu_path"]
      p ||= uri
      return p =~ rex ? "active" : "inactive"
    end
    
    def topic_dirs
      result = dirs.dup
      result.reject! {|d| d["topic"].nil? }
      return result
    end
    
  end
end