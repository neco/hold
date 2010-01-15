module Webrat
  module XML
    def self.css_to_xpath(*selectors)
      selectors.map do |rule|
        unless rule =~ %r{\A\.?/}
          Nokogiri::CSS.xpath_for(rule, :prefix => './/')
        else
          rule
        end
      end.flatten.uniq
    end
  end
end
