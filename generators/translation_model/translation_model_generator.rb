class TranslationModelGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_path, class_name, "#{class_name}Test"

      # Model, test, and fixture directories.
      m.directory File.join('app/models', class_path)
      #m.directory File.join('test/unit', class_path)
      #m.directory File.join('test/fixtures', class_path)

      # Model class, unit test, and fixtures.
      m.template 'model.rb',      File.join('app/models', class_path, "#{file_name}.rb")
      #m.template 'unit_test.rb',  File.join('test/unit', class_path, "#{file_name}_test.rb")
      #m.template 'fixtures.yml',  File.join('test/fixtures', class_path, "#{table_name}.yml")

      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}",
          :foreign_key => Inflector.foreign_key(class_name.sub('Translation',''))
        }, :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
      end
    end
  end
end
