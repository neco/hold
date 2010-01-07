module Webrat
  class Field < Element
    class << self
      def field_class(element)
        case element.name.downcase
        when "button"   then ButtonField
        when "select"   then SelectField
        when "textarea" then TextareaField
        else
          case Webrat::XML.attribute(element, "type").downcase
          when "checkbox" then CheckboxField
          when "hidden"   then HiddenField
          when "radio"    then RadioField
          when "password" then PasswordField
          when "file"     then FileField
          when "reset"    then ResetField
          when "submit"   then ButtonField
          when "button"   then ButtonField
          when "image"    then ButtonField
          else  TextField
          end
        end
      end

      def lowercase_attribute(attribute)
        upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        lower = 'abcdefghijklmnopqrstuvwxyz'
        "translate(#{attribute}, '#{upper}', '#{lower}')"
      end
      private :lowercase_attribute
    end
  end

  class TextField < Field
    def self.xpath_search
      [
        ".//input[#{lowercase_attribute('@type')} = 'text']",
        ".//input[not(@type)]"
      ]
    end
  end

  class PasswordField < Field
    def self.xpath_search
      [
        ".//input[#{lowercase_attribute('@type')} = 'password']"
      ]
    end
  end

  class ButtonField < Field
    def self.xpath_search
      [
        ".//button",
        ".//input[#{lowercase_attribute('@type')} = 'submit']",
        ".//input[#{lowercase_attribute('@type')} = 'button']",
        ".//input[#{lowercase_attribute('@type')} = 'image']"
      ]
    end
  end
end
