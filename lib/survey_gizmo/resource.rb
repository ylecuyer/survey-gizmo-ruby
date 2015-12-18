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
      # Get an array of resources.
      # @param [Hash] options - simple URL params at the top level, and SurveyGizmo "filters" at the :filters key
      #
      # example: { page: 2, filters: { field: "istestdata", operator: "<>", value: 1 } }
      #
      # The top level keys (e.g. page, resultsperpage) get encoded in the url, while the
      # contents of the array of hashes passed at the :filters key get turned into the format
      # SurveyGizmo expects for its internal filtering, for example:
      #
      # filter[field][0]=istestdata&filter[operator][0]=<>&filter[value][0]=1
      #
      # Set all_pages: true if you want the gem to page through all the available responses
      def all(conditions = {}, _deprecated_filters = {})
        conditions = merge_params(conditions, _deprecated_filters)
        fail ':all_pages and :page are mutually exclusive' if conditions[:page] && conditions[:all_pages]

        all_pages = conditions.delete(:all_pages)
        properties = conditions.dup
        conditions[:resultsperpage] = SurveyGizmo.configuration.results_per_page unless conditions[:resultsperpage]

        request_route = handle_route!(:create, conditions)
        response = RestResponse.new(SurveyGizmo.get(request_route + filters_to_query_string(conditions)))
        collection = response.data.map { |datum| datum.is_a?(Hash) ? new(datum) : datum }

        while all_pages && response.current_page < response.total_pages
          paged_filter = filters_to_query_string(conditions.merge(page: response.current_page + 1))
          response = RestResponse.new(SurveyGizmo.get(request_route + paged_filter))
          collection += response.data.map { |datum| datum.is_a?(Hash) ? new(datum) : datum }
        end

        # Add in the properties from the request because many of the important ones (like survey_id) are
        # not often part of the SurveyGizmo returned data
        properties.each do |k, v|
          next unless v && instance_methods.include?(k)
          collection.each { |c| c[k] ||= v }
        end

        # Sub questions are not pulled by default so we have to retrieve them manually
        # SurveyGizmo claims they will fix this bug and eventually all questions will be
        # returned in one request.
        if self == SurveyGizmo::API::Question
          collection += collection.map { |question| question.sub_questions }.flatten
        end

        collection
      end

      # Retrieve a single resource.  See usage comment on .all
      def first(conditions, _deprecated_filters = {})
        conditions = merge_params(conditions, _deprecated_filters)
        properties = conditions.dup

        response = RestResponse.new(SurveyGizmo.get(handle_route!(:get, conditions) + filters_to_query_string(conditions)))
        # Add in the properties from the conditions hash because many of the important ones (like survey_id) are
        # not often part of the SurveyGizmo's returned data
        new(properties.merge(response.data))
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
      def route(path, methods)
        Array(methods).each { |m| @paths[m] = path }
      end

      # Replaces the :page_id, :survey_id, etc strings defined in each model's URI routes with the
      # values being passed in interpolation hash with the same keys.
      #
      # This method has the SIDE EFFECT of deleting REST path related keys from interpolation_hash!
      def handle_route!(key, interpolation_hash)
        path = @paths[key]
        fail "No routes defined for `#{key}` in #{name}" unless path
        fail "User/password hash not setup!" if SurveyGizmo.default_params.empty?

        path.gsub(/:(\w+)/) do |m|
          raise SurveyGizmo::URLError, "Missing RESTful parameters in request: `#{m}`" unless interpolation_hash[$1.to_sym]
          interpolation_hash.delete($1.to_sym)
        end
      end

      private

      # Convert a [Hash] of params and internal surveygizmo style filters into a query string
      def filters_to_query_string(params = {})
        return '' unless params && params.size > 0

        url_params = {}
        filters = Array.wrap(params.delete(:filters) || [])

        filters.each_with_index do |filter, i|
          fail "Bad filter params: #{filter}" unless filter.is_a?(Hash) && [:field, :operator, :value].all? { |k| filter[k] }

          url_params["filter[field][#{i}]".to_sym]    = "#{filter[:field]}"
          url_params["filter[operator][#{i}]".to_sym] = "#{filter[:operator]}"
          url_params["filter[value][#{i}]".to_sym]    = "#{filter[:value]}"
        end

        uri = Addressable::URI.new
        uri.query_values = url_params.merge(params)
        "?#{uri.query}"
      end

      def merge_params(conditions, _deprecated_filters)
        $stderr.puts('Use of the 2nd hash parameter is deprecated.') unless _deprecated_filters.empty?
        conditions.merge(_deprecated_filters || {})
      end
    end

    # Save the resource to SurveyGizmo
    def save
      if id
        # Then it's an update, because we already know the surveygizmo assigned id
        RestResponse.new(SurveyGizmo.post(handle_route(:update), query: attributes_without_blanks))
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
      rest_response = RestResponse.new(SurveyGizmo.put(handle_route(:create), query: attributes_without_blanks))
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
      attributes.reject { |k,v| v.blank? }
    end

    private

    def handle_route(key)
      self.class.handle_route!(key, to_param_options)
    end
  end
end
