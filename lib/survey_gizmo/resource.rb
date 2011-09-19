module SurveyGizmo
  module Resource
    extend ActiveSupport::Concern
    
    included do
      include Virtus
    end
    
    module ClassMethods
      def get(id)
        response = SurveyGizmo.get("/#{id}", :query => SurveyGizmo.auth_params)
        if response.parsed_response['result_ok']
          resource = new(response.parsed_response['data'])
          resource.__send__(:clean!)
          resource
        else
          # do something
          # e = response.parsed_response['message']
          false
        end
      end

      def create(attributes = {})
        resource = new(attributes)
        resource.__send__(:_create)
        resource
      end
    end
    
    
    # @private
    def initialize(attributes = {})
      super(attributes)
    end
    
    
    
    def update(attributes = {})
      self.attributes = attributes
      self.save
    end
    
    def save
      response = SurveyGizmo.post("/#{self.id}", :query => self.attributes_with_auth)
      _result = response.parsed_response['result_ok']
      saved! if _result
      _result
    end
    
    # fetch resource from SurveyGizmo and reload the attributes
    def reload
      response = SurveyGizmo.get("/#{self.id}", :query => SurveyGizmo.auth_params)
      if response.parsed_response['result_ok']
        self.attributes = response.parsed_response['data']
        clean!
      else
        # do something
        # e = response.parsed_response['message']
        false
      end  
    end
    
    def destroy
      return false if new?
      response = SurveyGizmo.delete("/#{self.id}", :query => SurveyGizmo.auth_params)
      _result = response.parsed_response['result_ok']
      destroyed! if _result
      _result
    end
    
    def new?
      @_state.nil?
    end
    
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
    
    protected
    
    # @private
    def _create(attributes = {})
      response = SurveyGizmo.put('', :query => self.attributes_with_auth)
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
    def attributes_with_auth
      self.attributes.reject{|k,v| v.blank? }.merge(SurveyGizmo.auth_params)
    end
    
  end
end