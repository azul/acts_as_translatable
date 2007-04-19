class TranslationModel < ActiveRecord::Base
  
  include Reloadable::Subclasses
  self.abstract_class = true  
  
  @@enabled  = true
  @@base_language = :en
  @@language = :en

  cattr_reader :base_language
  cattr_reader :language
  
  LANGUAGES = { 
      :uk => 'Українська',
      :ru => 'Русский',
      :en => 'English',
      :de => 'Deutsch'
  }

  class <<self  
    
    def set_base_language(language)
      @@base_language = self.parse_language(language)
#       @@language = @@base_language
    end

    def set_language(language)
      @@language = self.parse_language(language)
    end

    def base_language?
      self.base_language == self.language
    end

    def enable
      @@enabled = true
    end

    def disable
      @@enabled = false
      true
    end
  
    def enabled?
      @@enabled
    end
    
    def disabled?
      !@@enabled
    end
    
    def parse_language(language)
      language = language.intern if language.kind_of?(String)
      raise ArgumentError, "bad format for #{language}" unless LANGUAGES.has_key?(language)
      language
    end
    
    def ensure_columns(attributes)
      attributes.each do |attr|
        unless self.column_names.include?(attr.to_s)
          self.connection.add_column(table_name, attr, :text)
        end
      end
    end
  
  end

end
