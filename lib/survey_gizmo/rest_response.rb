# This class normalizes the response returned by Survey Gizmo
class RestResponse
  attr_accessor :raw_response
  attr_accessor :response

  def initialize(rest_response)
    @raw_response = rest_response
    @response = rest_response.parsed_response
    return unless data

    # Handle really crappy [] notation in SG API, so far just in SurveyResponse
    (data.is_a?(Array) ? data : [data]).each do |datum|
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

  def ok?
    if ENV['GIZMO_DEBUG']
      ap 'SG Response: '
      ap @response
    end

    if @response['result_ok'] && @response['result_ok'].to_s.downcase == 'false' && @response['message'] && @response['code'] && @response['message'] =~ /service/i
      raise Exception, "#{@response['message']}: #{@response['code']}"
    end
    @response['result_ok'] && @response['result_ok'].to_s.downcase == 'true'
  end

  # The parsed JSON data of the response
  def data
    @_data ||= @response['data'] #|| {'id' => @response['id']}
  end

  # The error message if there is one
  def message
    @_message ||= @response['message']
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
