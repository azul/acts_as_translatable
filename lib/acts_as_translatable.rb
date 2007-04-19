module ActiveRecord
  module Acts #:nodoc:
    module Translatable #:nodoc:

      def self.included(base) # :nodoc:
        class << base
          unless respond_to? :old_construct_finder_sql_with_included_associations
            alias_method :old_construct_finder_sql_with_included_associations,
                         :construct_finder_sql_with_included_associations
          end
          unless respond_to? :old_column_aliases
            alias_method :old_column_aliases, :column_aliases
          end
        end
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        #
        # Options:
        #  +attributes+  *REQUIRED* - specify attributes that will be translated 
        #  +from+ - specify translation class name. (Default is class_name + Translation)
        #  +foreign_key+ - specify foreign key of translation model
        #  +language_key+ (Default is :language_id)
        #  +prefix+ (default translation)
        def acts_as_translatable(options = {})
          
          raise "set attributes to be translated" if options[:attributes].nil?
          from = options[:from] || "#{self.name}Translation"
          foreign_key = options[:foreign_key] || Inflector.foreign_key(base_class.name)
          language_key = options[:language_key] || 'language_id'
          prefix = options[:prefix] || 'translation'
          
          begin 
            translation = from.constantize
          rescue
            raise "TranslationModel '#{from}' does not exists"
          end
          translation.ensure_columns(options[:attributes]) 
          select = []
          column_names.each do |column|
            if options[:attributes].include?(column.intern)
              select << "COALESCE(#{translation.table_name}.#{column}, #{table_name}.#{column}) AS #{column}"
            else
              select << "#{table_name}.#{column} AS #{column}"
            end
          end
          select = select.join(", ")
          joins = " LEFT JOIN #{translation.table_name} ON" +
                  " #{translation.table_name}.#{foreign_key} =" +
                  " #{table_name}.#{primary_key} AND" +
                  " #{translation.table_name}.#{language_key} = "
                            
          write_inheritable_attribute(:acts_as_translatable_options, {
                                        :attributes => options[:attributes],
                                        :select => select,
                                        :joins => joins,
                                        :prefix => prefix,
                                        :table_name => translation.table_name })
          
          class_inheritable_reader :acts_as_translatable_options

          has_many :translations,
                   :class_name => from,
                   :dependent => :destroy
          
          has_one :translation,
                  :class_name => from,
                  :conditions => "#{language_key} = " + 
                                 "'" + '#{TranslationModel.language.to_s}' + "'"



          class <<self
            unless respond_to? :old_construct_finder_sql
              alias_method :old_construct_finder_sql, :construct_finder_sql
            end
          end
          extend ActiveRecord::Acts::Translatable::SingletonMethods
          include ActiveRecord::Acts::Translatable::InstanceMethods
        end
        
        def translation_columns
          @translation_columns ||= columns.reject {|c|
            !acts_as_translatable_options[:attributes].include?(c.name.intern)
          }
        end
        
        def define_translation_reader_method(attribute, prefix)
          self.class_eval <<-END_OF_METHOD
            attr = #{prefix}_#{attribute} 
            def #{attr} 
              if @attributes.has_key?(#{attr})
                @attributes['#{attr}']
              else
                nil
              end
            end
          END_OF_METHOD
        end
        
        private
          def translate_conditions!(conditions,attributes,table_name,translation_table_name)
            return if conditions.nil?
            where_clause = conditions.kind_of?(Array) ? conditions[0] : 
                                                        conditions
            attributes.each do |attr| 
              where_clause.gsub!("#{table_name}.#{attr}",
                                 "COALESCE(#{translation_table_name}.#{attr},#{table_name}.#{attr})")
            end
          end
          
          def translate_options_with_included_associations!(options,join_dependency)
            return if TranslationModel.disabled? || TranslationModel.base_language?
            joins = ""
            join_dependency.joins.each do |join|
              if join.active_record.respond_to?('acts_as_translatable_options')
                joins << " #{join.active_record.acts_as_translatable_options[:joins]}"
                joins << "'#{TranslationModel.language}'"
                translate_conditions!(options[:conditions],
                    join.active_record.acts_as_translatable_options[:attributes],
                    join.active_record.table_name,
                    join.active_record.acts_as_translatable_options[:table_name])
              end
            end          
            options[:joins]  = joins
          end
          
          def construct_finder_sql_with_included_associations(options,join_dependency)
            translate_options_with_included_associations!(options,join_dependency)
            old_construct_finder_sql_with_included_associations(options,join_dependency)
          end
          
          def column_aliases(join_dependency)
            if TranslationModel.disabled? || TranslationModel.base_language?
              return old_column_aliases(join_dependency)
            end
            join_dependency.joins.collect{|join| 
              join.column_names_with_alias.collect{|column_name, aliased_name|
                if join.active_record.respond_to?('acts_as_translatable_options') &&
                   join.active_record.acts_as_translatable_options[:attributes].include?(column_name.intern)
                  "COALESCE(#{join.active_record.acts_as_translatable_options[:table_name]}.#{connection.quote_column_name column_name}, #{join.aliased_table_name}.#{connection.quote_column_name column_name}) AS #{aliased_name}"
                else
                  "#{join.aliased_table_name}.#{connection.quote_column_name column_name} AS #{aliased_name}"
                end
              }
            }.flatten.join(", ")
          end      
      
      end#ClassMethods
      
      module SingletonMethods
        
        def translate_options!(options)
          return if TranslationModel.disabled? || TranslationModel.base_language?
					if options[:select] =~ /DISTINCT/
						options[:select] = "DISTINCT "
					else
						options[:select] = ""
					end
          options[:select] << acts_as_translatable_options[:select]
          options[:joins] ||= ''
          options[:joins] << acts_as_translatable_options[:joins]
          options[:joins] << "'#{TranslationModel.language}'"
          translate_conditions!(options[:conditions],
                                acts_as_translatable_options[:attributes],
                                table_name,
                                acts_as_translatable_options[:table_name])
        end
        
        private
          def construct_finder_sql(options)
            translate_options!(options)
            old_construct_finder_sql(options)
          end
          
      end#SingletonMethods

      
      module InstanceMethods
      end#InstanceMethods

    end#Tra1nslatable
  end#Acts
end#ActiveRecord
