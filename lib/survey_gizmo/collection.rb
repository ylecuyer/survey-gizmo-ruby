module SurveyGizmo
  class Collection
    include Enumerable
    
    def initialize(resource, name, values)
      @array          = Array(values)
      @collection     = []
      @loaded         = false
      @options        = resource.class.collections[name]
    end
    
    def length
      @array.length
    end
    
    def each
      lazy_load
      if block_given?
        @collection.each{ |o| yield(o)}
      else
        @collection.each
      end
    end
    
    def method_missing(meth, *args, &blk)
      @collection.send(meth, *args, &blk)
    end
    
    def model
      return @model if defined?(@model)
      name_string = @options[:target].is_a?(Symbol) ? ActiveSupport::Inflector.classify(@options[:target]) : @options[:target]
      @model = name_string[/::/] ? Object.const_get?(name_string) : Resource.descendants.detect{ |d| ActiveSupport::Inflector.demodulize(d.name) == name_string }
      raise NameError, "#{name_string} is not a descendant of SurveyGizmo::Resource" unless @model
      @model    
    end

    protected
    def lazy_load
      return if loaded?
      @collection = @array.map{|hash| load_object(hash) }
      mark_loaded
    end
    
    def load_object(obj_or_attributes)
      return obj_or_attributes if loaded?
      obj_or_attributes.is_a?(Hash) ? model.load(obj_or_attributes) : obj_or_attributes
    end
    
    def mark_loaded
      @loaded = true
    end
    
    def loaded?
      @loaded
    end
    
  end
end
