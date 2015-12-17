require 'set'
require 'addressable/uri'

module SurveyGizmo
  module Resource
    extend ActiveSupport::Concern

    included do
      include Virtus.model
      instance_variable_set('@paths', {})
      SurveyGizmo::Resource.descendants << self
    end

    # @return [Set] Every class that includes SurveyGizmo::Resource
    def self.descendants
      @descendants ||= Set.new
    end

    # These are methods that every API resource can use to access resources in SurveyGizmo
    module ClassMethods
      # Get an array of resources
      def all(conditions = {})
        fail ':all_pages and :page are mutually exclusive conditions' if conditions[:page] && conditions[:all_pages]

        all_pages = conditions.delete(:all_pages)
        conditions[:resultsperpage] = SurveyGizmo.configuration.results_per_page unless conditions[:resultsperpage]
        request_route = handle_route!(:create, conditions)

        response = RestResponse.new(SurveyGizmo.get(request_route + convert_filters_into_query_string(conditions)))
        collection = response.data.map { |datum| datum.is_a?(Hash) ? self.new(datum) : datum }

        while all_pages && response.current_page < response.total_pages
          paged_filter = convert_filters_into_query_string(conditions.merge(page: response.current_page + 1))
          response = RestResponse.new(SurveyGizmo.get(request_route + paged_filter))
          collection += response.data.map { |datum| datum.is_a?(Hash) ? self.new(datum) : datum }
        end

        # Add in the properties from the conditions hash because many of the important ones (like survey_id) are
        # not often part of the SurveyGizmo returned data
        conditions.keys.each do |k|
          if conditions[k] && instance_methods.include?(k)
            collection.each { |c| c[k] ||= conditions[k] }
          end
        end

        # Sub questions are not pulled by default so we have to retrieve them manually
        # SurveyGizmo claims they will fix this bug and eventually all questions will be
        # returned in one request.
        if self == SurveyGizmo::API::Question
          collection += collection.map { |question| question.sub_questions }.flatten
        end

        collection
      end

      # Retrieve a single resource.
      def first(conditions)
        response = RestResponse.new(SurveyGizmo.get(handle_route!(:get, conditions) + convert_filters_into_query_string(conditions)))
        # Add in the properties from the conditions hash because many of the important ones (like survey_id) are
        # not often part of the SurveyGizmo's returned data
        new(conditions.merge(response.data))
      end

      # Create a new resource.  Returns the newly created Resource instance.
      def create(attributes = {})
        resource = new(attributes)
        resource.create_record_in_surveygizmo
        resource
      end

      # Delete resources
      def destroy(conditions)
        RestResponse.new(SurveyGizmo.delete(handle_route!(:delete, conditions)))
      end

      # Define the path where a resource is located
      def route(path, options)
        methods = options[:via]
        methods = [:get, :create, :update, :delete] if methods == :any
        methods.is_a?(Array) ? methods.each { |m| @paths[m] = path } : (@paths[methods] = path)
      end

      # This method replaces the :page_id, :survey_id, etc strings defined in each model's URI routes with the
      # values being passed in interpolation hash with the same keys.
      #
      # This method has the side effect of deleting REST path related keys from interpolation_hash!
      def handle_route!(key, interpolation_hash)
        path = @paths[key]
        fail "No routes defined for `#{key}` in #{self.name}" unless path
        fail "User/password hash not setup!" if SurveyGizmo.default_params.empty?

        path.gsub(/:(\w+)/) do |m|
          raise(SurveyGizmo::URLError, "Missing RESTful parameters in request: `#{m}`") unless interpolation_hash[$1.to_sym]
          interpolation_hash.delete($1.to_sym)
        end
      end

      # Convert a [Hash] of filters into a query string
      # @param [Hash] filters - simple pagination or other options at the top level, and surveygizmo "filters" at the :filters key
      # @return [String]
      #
      # example input: { page: 2, filters: [{:field=>"istestdata", :operator=>"<>", :value=>1}] }
      #
      # The top level keys (e.g. page, resultsperpage) get simply encoded in the url, while the
      # contents of the array of hashes passed in the filters hash get turned into the format
      # SurveyGizmo expects for its internal filtering, for example:
      #
      # filter[field][0]=istestdata&filter[operator][0]=<>&filter[value][0]=1
      def convert_filters_into_query_string(filters = {})
        return '' unless filters && filters.size > 0

        output_filters = filters[:filters] || []
        filter_hash = {}
        output_filters.each_with_index do |filter,i|
          filter_hash.merge!(
            "filter[field][#{i}]".to_sym    => "#{filter[:field]}",
            "filter[operator][#{i}]".to_sym => "#{filter[:operator]}",
            "filter[value][#{i}]".to_sym    => "#{filter[:value]}",
          )
        end
        simple_filters = filters.reject { |k,v| k == :filters }
        filter_hash.merge!(simple_filters)

        uri = Addressable::URI.new
        uri.query_values = filter_hash
        "?#{uri.query}"
      end
    end

    # Save the resource to SurveyGizmo
    def save
      if id
        # Then it's an update, because we already know the surveygizmo assigned id
        RestResponse.new(SurveyGizmo.post(handle_route(:update), query: self.attributes_without_blanks))
      else
        create_record_in_surveygizmo
      end
    end

    # Repopulate the attributes based on what is on SurveyGizmo's servers
    def reload
      self.attributes = RestResponse.new(SurveyGizmo.get(handle_route(:get))).data
      self
    end

    # Delete the Resource from Survey Gizmo
    def destroy
      fail "No id; can't delete #{self.inspect}!" unless id
      RestResponse.new(SurveyGizmo.delete(handle_route(:delete)))
    end

    # Sets the hash that will be used to interpolate values in routes. It needs to be defined per model.
    # @return [Hash] a hash of the values needed in routing
    def to_param_options
      fail "Define #to_param_options in #{self.class.name}"
    end

    # Returns itself if successfully saved, but with attributes added by SurveyGizmo
    def create_record_in_surveygizmo(attributes = {})
      rest_response = RestResponse.new(SurveyGizmo.put(handle_route(:create), query: self.attributes_without_blanks))
      self.attributes = rest_response.data
      self
    end

    def inspect
      attribute_strings = self.class.attribute_set.map do |attrib|
        value = self.send(attrib.name)
        value = value.is_a?(Hash) ? value.inspect : value.to_s

        "  \"#{attrib.name}\" => \"#{value}\"\n" unless value.strip.blank?
      end.compact

      "#<#{self.class.name}:#{self.object_id}>\n#{attribute_strings.join}"
    end

    protected

    def attributes_without_blanks
      self.attributes.reject { |k,v| v.blank? }
    end

    private

    def handle_route(key)
      self.class.handle_route!(key, to_param_options)
    end
  end
end
