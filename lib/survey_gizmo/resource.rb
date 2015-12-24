require 'set'
require 'addressable/uri'

module SurveyGizmo
  module Resource
    extend ActiveSupport::Concern
    include Enumerable

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
        fail 'Block only makes sense with :all_pages' if block_given? && !conditions[:all_pages]
        $stderr.puts('WARNING: Only retrieving first page of results!') if conditions[:page].nil? && conditions[:all_pages].nil?

        all_pages = conditions.delete(:all_pages)
        conditions[:resultsperpage] = SurveyGizmo.configuration.results_per_page unless conditions[:resultsperpage]
        collection = []
        response = nil

        Enumerator.new do |yielder|
          while !response || (all_pages && response.current_page < response.total_pages)
            conditions[:page] = response ? response.current_page + 1 : 1
            response = Pester.survey_gizmo_ruby.retry do
              RestResponse.new(SurveyGizmo.get(create_route(:create, conditions)))
            end
            _collection = response.data.map { |datum| datum.is_a?(Hash) ? new(conditions.merge(datum)) : datum }

            # Sub questions are not pulled by default so we have to retrieve them manually.  SurveyGizmo
            # claims they will fix this bug and eventually all questions will be returned in one request.
            if self == SurveyGizmo::API::Question
              _collection += _collection.map { |question| question.sub_questions }.flatten
            end
            _collection.each { |e| yielder.yield(e) }
          end
        end
      end

      # Retrieve a single resource.  See usage comment on .all
      def first(conditions, _deprecated_filters = {})
        conditions = merge_params(conditions, _deprecated_filters)
        response = Pester.survey_gizmo_ruby.retry do
          RestResponse.new(SurveyGizmo.get(create_route(:get, conditions)))
        end

        # Add in properties from the conditions hash because many important ones (like survey_id) are not returned
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
        RestResponse.new(SurveyGizmo.delete(create_route(:delete, conditions)))
      end

      # Define the path where a resource is located
      def route(path, methods)
        Array.wrap(methods).each { |m| @paths[m] = path }
      end

      # Replaces the :page_id, :survey_id, etc strings defined in each model's URI routes with the
      # values being passed in the params hash with the same keys.
      def create_route(key, params)
        path = @paths[key]
        fail "No routes defined for `#{key}` in #{name}" unless path
        fail "User/password hash not setup!" if SurveyGizmo.default_params.empty?

        url_params = params.dup
        rest_path = path.gsub(/:(\w+)/) do |m|
          fail SurveyGizmo::URLError, "Missing RESTful parameters in request: `#{m}`" unless url_params[$1.to_sym]
          url_params.delete($1.to_sym)
        end

        rest_path + filters_to_query_string(url_params)
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
        RestResponse.new(SurveyGizmo.post(create_route(:update), query: attributes_without_blanks))
      else
        create_record_in_surveygizmo
      end
    end

    # Repopulate the attributes based on what is on SurveyGizmo's servers
    def reload
      self.attributes = RestResponse.new(SurveyGizmo.get(create_route(:get))).data
      self
    end

    # Delete the Resource from Survey Gizmo
    def destroy
      fail "No id; can't delete #{self.inspect}!" unless id
      RestResponse.new(SurveyGizmo.delete(create_route(:delete)))
    end

    # Sets the hash that will be used to interpolate values in routes. It needs to be defined per model.
    # @return [Hash] a hash of the values needed in routing
    def to_param_options
      fail "Define #to_param_options in #{self.class.name}"
    end

    # Returns itself if successfully saved, but with attributes added by SurveyGizmo
    def create_record_in_surveygizmo(attributes = {})
      rest_response = RestResponse.new(SurveyGizmo.put(create_route(:create), query: attributes_without_blanks))
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

    def create_route(key)
      self.class.create_route(key, to_param_options)
    end
  end
end
