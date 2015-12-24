require 'faraday_middleware/response_middleware'

module FaradayMiddleware
  class ParseSurveyGizmo < ResponseMiddleware
    Faraday::Response.register_middleware(surveygizmo_data: self)

    define_parser do |body|
      return unless body['data']

      # Handle really crappy [] notation in SG API, so far just in SurveyResponse
      Array.wrap(body['data']).compact.each do |datum|
        unless datum['datesubmitted'].blank?
          # SurveyGizmo returns date information in EST but does not provide time zone information.
          # See https://surveygizmov4.helpgizmo.com/help/article/link/date-and-time-submitted
          datum['datesubmitted'] = datum['datesubmitted'] + ' EST'
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
    end

    private

    def cleanup_attribute_name(attr)
      attr.downcase.gsub(/[^[:alnum:]]+/, '_')
                   .gsub(/(url|variable|standard|shown)/, '')
                   .gsub(/_+/, '_')
                   .gsub(/^_/, '')
                   .gsub(/_$/, '')
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
  end
end

# This class normalizes the data returned by Survey Gizmo
module SurveyGizmo
  class RestData
    attr_accessor :raw_response
    attr_accessor :parsed_response

    def initialize(http_response)
      @raw_response = http_response
      @parsed_response = http_response.body

      return unless data

    end

    # The parsed JSON data of the response
    def data
      @parsed_response['data']
    end

    # The error message if there is one
    def message
      @parsed_response['message']
    end

    def current_page
      @parsed_response['page'].to_i
    end

    def total_pages
      @parsed_response['total_pages'].to_i
    end
  end
end
