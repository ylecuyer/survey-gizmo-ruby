require 'set'
require 'addressable/uri'

module SurveyGizmo
  module Resource
    extend ActiveSupport::Concern

    included do
      include Virtus.model
      instance_variable_set('@paths', {})
      instance_variable_set('@collections', {})
      SurveyGizmo::Resource.descendants << self
    end

    # @return [Set] Every class that includes SurveyGizmo::Resource
    def self.descendants
      @descendants ||= Set.new
    end

    # These are methods that every API resource has to access resources
    # in Survey Gizmo
    module ClassMethods

      # Convert a [Hash] of filters into a query string
      # @param [Hash] filters - simple pagination or other options at the top level, and surveygizmo "filters" at the :filters key
      # @return [String]
      #
      # example input: {page: 2, filters: [{:field=>"istestdata", :operator=>"<>", :value=>1}]}
      # The top level keys (e.g. page, resultsperpage) get simply encoded in the url, while the contents of the array of hashes
      # passed at filters[:filters] gets turned into the format surveygizmo expects, for example:
      #
      # filter[field][0]=istestdata&filter[operator][0]=<>&filter[value][0]=1
      def convert_filters_into_query_string(filters = nil)
        if filters && filters.size > 0
          output_filters = filters[:filters] || []
          filter_hash = {}
          output_filters.each_with_index do |filter,i|
            filter_hash.merge!({
              "filter[field][#{i}]".to_sym => "#{filter[:field]}",
              "filter[operator][#{i}]".to_sym => "#{filter[:operator]}",
              "filter[value][#{i}]".to_sym => "#{filter[:value]}",
            })
          end
          simple_filters = filters.reject {|k,v| k == :filters}
          filter_hash.merge!(simple_filters)

          uri = Addressable::URI.new
          uri.query_values = filter_hash
          "?#{uri.query}"
        else
          ''
        end
      end

      # Get a list of resources
      # @param [Hash] conditions
      # @param [Hash] filters
      # @return [SurveyGizmo::Collection, Array]
      def all(conditions = {}, filters = nil)
        response = Response.new SurveyGizmo.get(handle_route(:create, conditions) + convert_filters_into_query_string(filters))
        if response.ok?
          _collection = SurveyGizmo::Collection.new(self, nil, response.data)
          _collection.send(:options=, {:target => self, :parent => self})
          _collection
        else
          []
        end
      end

      # Get the first resource
      # @param [Hash] conditions
      # @param [Hash] filters
      # @return [Object, nil]
      def first(conditions = {}, filters = nil)
        response = Response.new SurveyGizmo.get(handle_route(:get, conditions) + convert_filters_into_query_string(filters))
        response.ok? ? load(conditions.merge(response.data)) : nil
      end

      # Create a new resource
      # @param [Hash] attributes
      # @return [Resource]
      #   The newly created Resource instance
      def create(attributes = {})
        resource = new(attributes)
        resource.__send__(:_create)
        resource
      end

      # Copy a resource
      # @param [Integer] id
      # @param [Hash] attributes
      # @return [Resource]
      #   The newly created resource instance
      def copy(attributes = {})
        attributes[:copy] = true
        resource = new(attributes)
        resource.__send__(:_copy)
        resource
      end

      # Deleted the Resource from Survey Gizmo
      # @param [Hash] conditions
      # @return [Boolean]
      def destroy(conditions)
        response = Response.new SurveyGizmo.delete(handle_route(:delete, conditions))
        response.ok?
      end

      # Define the path where a resource is located
      # @param [String] path
      #   the path in Survey Gizmo for the resource
      # @param [Hash] options
      # @option options [Array] :via
      #     which is `:get`, `:create`, `:update`, `:delete`, or `:any`
      # @scope class
      def route(path, options)
        methods = options[:via]
        methods = [:get, :create, :update, :delete] if methods == :any
        methods.is_a?(Array) ? methods.each{|m| @paths[m] = path } : (@paths[methods] = path)
        nil
      end

      # @api private
      def load(attributes = {})
        resource = new(attributes)
        resource.__send__(:clean!)
        resource
      end

      # Defines a new collection. These are child objects of the resource.
      # @macro [new] collection
      #   @param [Symbol] resource_name the name of the collection, pluralized
      #   @param [Class] model and optional class name if the class name does not match the resource_name
      #   @return [Collection]
      #     the $1 collection
      #   @scope instance
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

      # @api private
      def collections
        @collections.dup.freeze
      end

      # @api private
      def handle_route(key, *interp)
        path = @paths[key]
        raise "No routes defined for `#{key}` in #{self.name}" unless path
        options = interp.last.is_a?(Hash) ? interp.pop : path.scan(/:(\w+)/).inject({}){|hash, k| hash.merge(k.to_sym => interp.shift) }
        path.gsub(/:(\w+)/) do |m|
          options[$1.to_sym].tap { |result| raise(SurveyGizmo::URLError, "Missing parameters in request: `#{m}`") unless result }
        end
      end
    end

    # Updates attributes and saves this Resource instance
    #
    # @param [Hash] attributes
    #   attributes to be updated
    #
    # @return [Boolean]
    #   true if resource is saved
    def update(attributes = {})
      self.attributes = attributes
      self.save
    end

    # Save the instance to Survey Gizmo
    #
    # @return [Boolean]
    #   true if Resource instance is saved
    def save
      if new?
        _create
      else
        handle_response SurveyGizmo.post(handle_route(:update), :query => self.attributes_without_blanks) do
          warn _response.message if !_response.ok? && ENV['GIZMO_DEBUG']
          _response.ok? ? saved! : false
        end
      end
    end

    # fetch resource from SurveyGizmo and reload the attributes
    # @return [self, false]
    #   Returns the object, if saved. Otherwise returns false.
    def reload
      handle_response SurveyGizmo.get(handle_route(:get)) do
        if _response.ok?
          self.attributes = _response.data
          clean!
        else
          false
        end
      end
    end

    # Deleted the Resource from Survey Gizmo
    # @return [Boolean]
    def destroy
      return false if new? || destroyed?
      handle_response SurveyGizmo.delete(handle_route(:delete)) do
        _response.ok? ? destroyed! : false
      end
    end

    # The state of the current Resource
    # @api private
    def new?
      @_state.nil?
    end

    # @todo This seemed like a good way to prevent accidently trying to perform an action
    #   on a record at a point when it would fail. Not sure if it's really necessary though.
    [:clean, # stored and not dirty
      :saved, # stored and not modified
      :destroyed, # duh!
      :zombie  # needs to be stored
    ].each do |state|
      # Change the method state to $1
      define_method("#{state}!") do
        @_state = state
        true
      end

      # Inquire about the method state if $1
      define_method("#{state}?") do
        @_state == state
      end

      private "#{state}!"
    end

    # Sets the hash that will be used to interpolate values in routes. It needs to be defined per model.
    # @return [Hash] a hash of the values needed in routing
    def to_param_options
      raise "Define #to_param_options in #{self.class.name}"
    end

    # Any errors returned by Survey Gizmo
    # @return [Array]
    def errors
      @errors ||= []
    end

    # @return [Hash] The raw JSON returned by Survey Gizmo
    def raw_response
      _response.response if _response
    end

    # @visibility private
    def inspect
      if ENV['GIZMO_DEBUG']
        ap "CLASS: #{self.class}"
      end

      attribute_strings = self.class.attribute_set.map do |attrib|
        if ENV['GIZMO_DEBUG']
          ap attrib
          ap attrib.name
          ap self.send(attrib.name)
          ap self.send(attrib.name).class
        end

        if self.send(attrib.name).class == Hash
          value = self.send(attrib.name).inspect
        else
          value = self.send(attrib.name).to_s
        end

        "  \"#{attrib.name}\" => \"#{value}\"\n" unless value.strip.blank?
      end.compact

      "#<#{self.class.name}:#{self.object_id}>\n#{attribute_strings.join()}"
    end

    # This class normalizes the response returned by Survey Gizmo
    class Response
      attr_reader :response

      def ok?
        if ENV['GIZMO_DEBUG']
          puts "SG Response: "
          ap @response
        end

        if @response['result_ok'] && @response['result_ok'].to_s.downcase == 'false' && @response['message'] && @response['code'] && @response['message'] =~ /service/i
          raise Exception, "#{@response['message']}: #{@response['code']}"
        end
        @response['result_ok'] && @response['result_ok'].to_s.downcase == 'true'
      end

      # The parsed JSON data of the response
      def data
        unless @_data
          @_data = {'id' => @response['id']} if @response && @response['id']
          @_data = @response['data'] if @response && @response['data']
        end

        @_data ||= {}
      end

      # The error message if there is one
      def message
        @_message ||= @response['message']
      end


      private

      def cleanup_attribute_name(attr)
        attr.downcase.gsub(/[^[:alnum:]]+/,'_').gsub(/(url|variable|standard|shown)/,'').gsub(/_+/,'_').gsub(/^_/,'').gsub(/_$/,'')
      end

      def find_attribute_parent(attr)
        case attr.downcase
        when /url/
          'url'
        when /variable.*standard/
          'meta'
        when /variable.*shown/
          'shown'
        when /variable/
          'variable'
        when /question/
          'answers'
        end
      end

      def initialize(response)
        @response = response.parsed_response
        return unless data

        # Handle really crappy [] notation in SG API, so far just in SurveyResponse
        (@_data.is_a?(Array) ? @_data : [@_data]).each do |data_item|
          data_item.keys.grep(/^\[/).each do |key|
            next if data_item[key].nil? || data_item[key].length == 0

            parent = find_attribute_parent(key)
            data_item[parent] ||= {}

            case key.downcase
            when /(url|variable.*standard)/
              data_item[parent][cleanup_attribute_name(key).to_sym] = data_item[key]
            when /variable.*shown/
              data_item[parent][cleanup_attribute_name(key).to_i] = data_item[key].include?('1')
            when /variable/
              data_item[parent][cleanup_attribute_name(key).to_i] = data_item[key].to_i
            when /question/
              data_item[parent][key] = data_item[key]
            end

            data_item.delete(key)
          end
        end unless @_data.nil?
      end
    end


    protected

    def attributes_without_blanks
      self.attributes.reject{|k,v| v.blank? }
    end

    private
    # The response object from SurveyGizmo. Useful for viewing the raw data returned
    attr_reader :_response

    def set_response(http)
      @_response = Response.new(http)
    end

    def handle_route(key)
      self.class.handle_route(key, to_param_options)
    end

    def handle_response(resp, &block)
      set_response(resp)
      (self.errors << _response.message) unless _response.ok?
      self.errors.clear if !self.errors.empty? && _response.ok?
      instance_eval(&block)
    end

    def _create(attributes = {})
      http = SurveyGizmo.put(handle_route(:create), :query => self.attributes_without_blanks)
      handle_response http do
        if _response.ok?
          if ENV['GIZMO_DEBUG']
            puts "SG Set attributes during _create"
            ap @_response
          end
          self.attributes = _response.data
          saved!
        else
          false
        end
      end
    end

    def _copy(attributes = {})
      http = SurveyGizmo.post(handle_route(:update), :query => self.attributes_without_blanks)
      handle_response http do
        if _response.ok?
          self.attributes = _response.data
          saved!
        else
          false
        end
      end
    end

  end
end
