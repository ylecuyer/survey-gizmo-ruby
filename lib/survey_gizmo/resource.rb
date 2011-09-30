require "set"

module SurveyGizmo
  module Resource
    extend ActiveSupport::Concern
    
    included do
      include Virtus
      instance_variable_set('@paths', {})
      instance_variable_set('@collections', {})
      SurveyGizmo::Resource.descendants << self
    end
    
    def self.descendants
      @descendants ||= Set.new
    end
    
    module ClassMethods
      
      # Get a list of resources
      # @param [Hash] conditions
      # @return [SurveGizmo::Collection, false]
      def all(conditions = {})
        response = SurveyGizmo.get(handle_route(:create, conditions))
        if response.parsed_response['result_ok']
          collection = SurveyGizmo::Collection.new(self, nil, response.parsed_response['data'])
          collection.send(:options=, {:target => self, :parent => self})
          collection
        else
          # do something
          # e = response.parsed_response['message']
          false
        end
      end
      
      # Get the first resource
      # @param [Hash] conditions
      # @return [Object, false]
      def first(conditions)
        response = SurveyGizmo.get(handle_route(:get, conditions))
        if response.parsed_response['result_ok']
          resource = new(conditions.merge(response.parsed_response['data']))
          resource.__send__(:clean!)
          resource
        else
          # do something
          # e = response.parsed_response['message']
          false
        end
      end
      
      # Create a new resource
      # @param [Hash] attributes
      # @return [Object]
      def create(attributes = {})
        resource = new(attributes)
        resource.__send__(:_create)
        resource
      end
      
      # Define the path where a resource is located
      # @param [String] path the path in Survey Gizmo for the resource
      # @param [Hash]   options must include `:via` which is `:get`, `:create`, `:update`, `:delete`, or `:any`
      def route(path, options)
        methods = options[:via]
        methods = [:get, :create, :update, :delete] if methods == :any
        methods.is_a?(Array) ? methods.each{|m| @paths[m] = path } : (@paths[methods] = path)
        nil
      end
      
      
      def load(attributes = {})
        resource = new(attributes)
        resource.__send__(:clean!)
        resource
      end
      
      def collection(resource_name, model = nil)
        @collections[resource_name] = {:parent => self, :target => (model ? model : resource_name)} # workaround for weird bug with passing a class to Collection
        class_eval(<<-EOS)
          def #{resource_name}
            @#{resource_name} ||= []
          end
          
          def #{resource_name}=(array)
            @#{resource_name} = SurveyGizmo::Collection.new(#{self}, :#{resource_name}, array)
          end
        EOS
      end
      
      def collections
        @collections
      end
      
      def handle_route(key, *interp)
        path = @paths[key]
        raise "No routes defined for `#{key}` in #{self.name}" unless path
        options = interp.last.is_a?(Hash) ? interp.pop : path.scan(/:(\w+)/).inject({}){|hash, k| hash.merge(k.to_sym => interp.shift) }
        path.gsub(/:(\w+)/){|m| options[$1.to_sym] }
      end
    end
        
    def update(attributes = {})
      self.attributes = attributes
      self.save
    end
    
    def save
      response = SurveyGizmo.post(handle_route(:update), :query => self.attributes_without_blanks)
      _result = response.parsed_response['result_ok']
      saved! if _result
      _result
    end
    
    # fetch resource from SurveyGizmo and reload the attributes
    def reload
      response = SurveyGizmo.get(handle_route(:get))
      if response.parsed_response['result_ok']
        self.attributes = response.parsed_response['data']
        clean!
        self
      else
        # do something
        # e = response.parsed_response['message']
        false
      end  
    end
    
    def destroy
      return false if new?
      response = SurveyGizmo.delete(handle_route(:delete))
      _result = response.parsed_response['result_ok']
      destroyed! if _result
      _result
    end
    
    def new?
      @_state.nil?
    end
    
    # @todo This seemed like a good way to prevent accidently trying to perform an action
    # on a record at a point when it would fail. Not sure if it's really necessary though.
    [:clean, # stored and not dirty
      :saved, # stored and not modified
      :destroyed, # duh!
      :zombie  # needs to be stored
    ].each do |state|
      define_method("#{state}!") do
        @_state = state
      end
      
      define_method("#{state}?") do
        @_state == state
      end
      
      private "#{state}!"
    end
    
    # Sets the hash that will be used to interpolate values in routes. It needs to be defined per model.
    # @return [Hash] a hash of the values needed in routing. ie. {:id => self.id}
    def to_param_options
      raise "Define #to_param_options in #{self.class.name}"
    end
    
    def inspect
      attrs = self.class.attributes.map do |attrib|
        value = attrib.get!(self).inspect

        "#{attrib.instance_variable_name}=#{value}"
      end

      "#<#{self.class.name}:#{self.object_id} #{attrs.join(' ')}>"
    end

    protected
    
    def handle_route(key)
      self.class.handle_route(key, to_param_options)
    end
    
    # @private
    def _create(attributes = {})
      response = SurveyGizmo.put(handle_route(:create), :query => self.attributes_without_blanks)
      if response.parsed_response['result_ok']
        self.attributes = response.parsed_response['data']
        saved!
      else
        # do something
        # e = response.parsed_response['message']
        false
      end
    end
    
    # @private
    def attributes_without_blanks
      self.attributes.reject{|k,v| v.blank? }
    end
    
  end
end