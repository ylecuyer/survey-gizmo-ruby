require 'set'
require 'addressable/uri'

module SurveyGizmo
  class URLError < RuntimeError; end

  module Resource
    extend ActiveSupport::Concern

    included do
      include Virtus.model
      instance_variable_set('@route', nil)
      SurveyGizmo::Resource.descendants << self
    end

    def self.descendants
      @descendants ||= Set.new
    end

    # These are methods that every API resource can use to access resources in SurveyGizmo
    module ClassMethods
      # Get an enumerator of resources.
      # @param [Hash] conditions - URL and pagination params with SurveyGizmo "filters" at the :filters key
      #
      # Set all_pages: true if you want the gem to page through all the available responses
      #
      # example: { page: 2, filters: { field: "istestdata", operator: "<>", value: 1 } }
      #
      # The top level keys (e.g. :page, :resultsperpage) get encoded in the url, while the
      # contents of the array of hashes passed at the :filters key get turned into the format
      # SurveyGizmo expects for its internal filtering.
      #
      # Properties from the conditions hash (e.g. survey_id) will be added to the returned objects
      def all(conditions = {})
        fail ':all_pages and :page are mutually exclusive' if conditions[:page] && conditions[:all_pages]
        $stderr.puts('WARNING: Only retrieving first page of results!') if conditions[:page].nil? && conditions[:all_pages].nil?

        all_pages = conditions.delete(:all_pages)
        conditions[:resultsperpage] = SurveyGizmo.configuration.results_per_page unless conditions[:resultsperpage]
        response = nil

        Enumerator.new do |yielder|
          while !response || (all_pages && response['page'] < response['total_pages'])
            conditions[:page] = response ? response['page'] + 1 : 1
            response = Connection.get(create_route(:create, conditions)).body
            collection = response['data'].map { |datum| datum.is_a?(Hash) ? new(conditions.merge(datum)) : datum }

            # Sub questions are not pulled by default so we have to retrieve them manually.  SurveyGizmo
            # claims they will fix this bug and eventually all questions will be returned in one request.
            if self == SurveyGizmo::API::Question
              collection += collection.flat_map { |question| question.sub_questions }
            end

            collection.each { |e| yielder.yield(e) }
          end
        end
      end

      # Retrieve a single resource.  See usage comment on .all
      def first(conditions = {})
        new(conditions.merge(Connection.get(create_route(:get, conditions)).body['data']))
      end

      # Create a new resource.  Returns the newly created Resource instance.
      def create(attributes = {})
        new(attributes).save
      end

      # Delete resources
      def destroy(conditions)
        Connection.delete(create_route(:delete, conditions))
      end

      private

      # Replaces the :page_id, :survey_id, etc strings defined in each model's URI routes with the
      # values being passed in the params hash with the same keys.
      def create_route(method, params)
        if @route.is_a?(Hash)
          route = @route[method]
        else
          route = @route
          route += '/:id' if [:get, :update, :delete].include?(method)
        end

        fail "No route defined for #{method} on #{name}" unless route
        fail "Not configured" unless SurveyGizmo.configuration

        url_params = params.dup
        rest_path = route.gsub(/:(\w+)/) do |m|
          fail SurveyGizmo::URLError, "Missing RESTful parameters in request: `#{m}`" unless url_params[$1.to_sym]
          url_params.delete($1.to_sym)
        end

        SurveyGizmo.configuration.api_version + rest_path + filters_to_query_string(url_params)
      end

      # Convert a [Hash] of params and internal surveygizmo style filters into a query string
      #
      # The hashes at the :filters key get turned into URL params like:
      # # filter[field][0]=istestdata&filter[operator][0]=<>&filter[value][0]=1
      def filters_to_query_string(params = {})
        return '' unless params && params.size > 0

        url_params = {}
        Array.wrap(params.delete(:filters)).each_with_index do |filter, i|
          fail "Bad filter params: #{filter}" unless filter.is_a?(Hash) && [:field, :operator, :value].all? { |k| filter[k] }

          url_params["filter[field][#{i}]".to_sym]    = "#{filter[:field]}"
          url_params["filter[operator][#{i}]".to_sym] = "#{filter[:operator]}"
          url_params["filter[value][#{i}]".to_sym]    = "#{filter[:value]}"
        end

        uri = Addressable::URI.new(query_values: url_params.merge(params))
        "?#{uri.query}"
      end
    end

    ### BELOW HERE ARE INSTANCE METHODS ###

    # If we have an id, it's an update, because we already know the surveygizmo assigned id
    # Returns itself if successfully saved, but with attributes (like id) added by SurveyGizmo
    def save
      method, path = id ? [:post, :update] : [:put, :create]
      rest_response = Connection.send(method, create_route(path), attributes_without_blanks)
      self.attributes = rest_response.body['data']
      self
    end

    # Repopulate the attributes based on what is on SurveyGizmo's servers
    def reload
      self.attributes = Connection.get(create_route(:get)).body['data']
      self
    end

    # Delete the Resource from Survey Gizmo
    def destroy
      fail "No id; can't delete #{self.inspect}!" unless id
      Connection.delete(create_route(:delete))
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

    def create_route(method)
      self.class.send(:create_route, method, to_param_options)
    end
  end
end
