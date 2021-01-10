# frozen_string_literal: true

require 'httparty'

class Currency
  URL = 'https://cbr.ru/currency_base/daily/'
  TYPE = 'USD' # default

  #
  # type can be EUR and etc (full list at URL)
  #
  def self.value(type = TYPE)
    response = HTTParty.get(URL).parsed_response

    %r[#{type}.+?([\d,]+)\s*<[^\d]+tr]m.match(response)[1] || 'Parse error'
  rescue
    'Service error'
  end
end
