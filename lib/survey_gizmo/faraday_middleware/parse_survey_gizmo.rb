require 'faraday_middleware/response_middleware'

module SurveyGizmo
  class RateLimitExceededError < RuntimeError; end
  class BadResponseError < RuntimeError; end

  class ParseSurveyGizmo < FaradayMiddleware::ResponseMiddleware
    Faraday::Response.register_middleware(parse_survey_gizmo_data: self)

    PAGINATION_FIELDS = [
      'page',
      'results_per_page',
      'total_count',
      'total_pages'
    ]

    TIME_FIELDS = [
      'created_on',
      'datecreated',
      'datemodified',
      'datesubmitted',
      'date_created',
      'date_modified',
      'date_submitted',
      'modified_on'
    ]

    def call(environment)
      @app.call(environment).on_complete do |response|
        fail RateLimitExceededError if response.status == 429
        fail BadResponseError, "Bad response code #{response.status} in #{response.inspect}" unless response.status == 200
        fail BadResponseError, response.body['message'] unless response.body['result_ok'] && response.body['result_ok'].to_s =~ /^true$/i

        process_response(response)
      end
    end

    define_parser do |body|
      PAGINATION_FIELDS.each { |n| body[n] = body[n].to_i if body[n] }

      next body unless body['data']

      # Handle really crappy [] notation in SG API, so far just in SurveyResponse
      Array.wrap(body['data']).compact.each do |datum|
        # SurveyGizmo returns date information using US/Eastern or Berlin timezone depending on which URI you use, but
        # does not return any information about the timezone.
        # See https://apihelp.surveygizmo.com/help/article/link/surveyresponse-returned-fields#examplereturns
        TIME_FIELDS.each do |time_key|
          next if datum[time_key].blank?
          datum[time_key] = ActiveSupport::TimeZone.new(SurveyGizmo.configuration.api_time_zone).parse(datum[time_key])
        end

        datum.keys.grep(/^\[/).each do |key|
          next if datum[key].nil? || datum[key].length == 0

          parent = find_attribute_parent(key)
          datum[parent] ||= {}

          case key.downcase
          when /(url|variable.*standard)/
            datum[parent][cleanup_attribute_name(key).to_sym] = datum[key]
          when /variable.*shown/
            datum[parent][cleanup_attribute_name(key).to_i] = datum[key].include?('1')
          when /variable/
            datum[parent][cleanup_attribute_name(key).to_i] = datum[key].to_i
          when /question/
            datum[parent][key] = datum[key]
          end

          datum.delete(key)
        end
      end

      body
    end

    private

    def self.cleanup_attribute_name(attr)
      attr.downcase.gsub(/[^[:alnum:]]+/, '_')
                   .gsub(/(url|variable|standard|shown)/, '')
                   .gsub(/_+/, '_')
                   .gsub(/^_|_$/, '')
    end

    def self.find_attribute_parent(attr)
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
  end
end
