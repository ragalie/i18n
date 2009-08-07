require 'i18n/backend/base'
require 'i18n/backend/active_record/translation'

module I18n
  module Backend
    class ActiveRecord < Base
      def reload!
      end

      def store_translations(locale, data)
        separator = I18n.default_separator # TODO allow to pass as an option?
        wind_keys(data).each do |key, v|
          Translation.locale(locale).lookup(expand_keys(key, separator), separator).delete_all
          Translation.create(:locale => locale.to_s, :key => key, :value => v)
        end
      end

      def available_locales
        begin
          Translation.available_locales
        rescue ::ActiveRecord::StatementInvalid
          []
        end
      end

      protected

        def lookup(locale, key, scope = [], separator = nil)
          return unless key

          separator ||= I18n.default_separator
          key = (Array(scope) + Array(key)).join(separator)

          result = Translation.locale(locale).lookup(key, separator).all
          if result.empty?
            return nil
          elsif result.first.key == key
            return result.first.value 
          else
            chop_range = (key.size + separator.size)..-1
            result = result.inject({}) do |hash, r|
              hash[r.key.slice(chop_range)] = r.value
              hash
            end
            deep_symbolize_keys(unwind_keys(result))
          end
        end
        
        # For a key :'foo.bar.baz' return ['foo', 'foo.bar', 'foo.bar.baz']
        def expand_keys(key, separator = I18n.default_separator)
          key.to_s.split(separator).inject([]) do |keys, key|
            keys << [keys.last, key].compact.join(separator)
          end
        end
    end
  end
end