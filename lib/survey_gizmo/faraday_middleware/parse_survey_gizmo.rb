require 'faraday_middleware/response_middleware'

module SurveyGizmo
  class ParseSurveyGizmo < FaradayMiddleware::ResponseMiddleware
    Faraday::Response.register_middleware(parse_survey_gizmo_data: self)

    def parse_response?(env)
      true
    end

    define_parser do |body|
      ['total_count', 'page', 'total_pages', 'results_per_page'].each do |n|
        body[n] = body[n].to_i if body[n]
      end

      next body unless body['data']

      # Handle really crappy [] notation in SG API, so far just in SurveyResponse
      Array.wrap(body['data']).compact.each do |datum|
        # SurveyGizmo returns date information in EST but does not provide time zone information.
        # See https://surveygizmov4.helpgizmo.com/help/article/link/date-and-time-submitted
        ['datesubmitted', 'created_on', 'modified_on', 'datecreated', 'datemodified'].each do |date_key|
          datum[date_key] = datum[date_key] + ' EST' unless datum[date_key].blank?
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
