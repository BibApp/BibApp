class ResourcefulScaffoldGenerator < Rails::Generator::NamedBase
  attr_reader   :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_underscore_name,
                :controller_plural_name
  alias_method  :controller_file_name,  :controller_underscore_name
  alias_method  :controller_table_name, :controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super

    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@name.pluralize)
    @controller_class_name_without_nesting, @controller_underscore_name, @controller_plural_name = inflect_names(base_name)

    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
  end
  
  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions(controller_class_path, "#{controller_class_name}Controller", "#{controller_class_name}Helper")
      m.class_collisions(class_path, "#{class_name}")

      # Controller, helper, views, and test directories.
      m.directory(File.join('app/models', class_path))
      m.directory(File.join('app/controllers', controller_class_path))
      m.directory(File.join('app/helpers', controller_class_path))
      m.directory(File.join('app/views', controller_class_path, controller_file_name))
      m.directory(File.join('test/functional', controller_class_path))
      m.directory(File.join('test/unit', class_path))
      m.directory(File.join('test/fixtures', class_path))

      # Views
      for action in scaffold_views
        m.template("view_#{action}.haml", File.join('app/views', controller_class_path, controller_file_name, "#{action}.html.haml"))
      end
      m.template('view_partial.haml', File.join('app/views', controller_class_path, controller_file_name, "_#{singular_name}.html.haml"))

      # Helper
      m.template('helper.rb', File.join('app/helpers', controller_class_path, "#{controller_file_name}_helper.rb"))

      # Model
      m.template('model.rb', File.join('app/models', class_path, "#{file_name}.rb"))

      unless options[:skip_migration]
        m.migration_template('migration.rb', 'db/migrate', 
          :assigns => {
            :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}",
            :attributes     => attributes
          },
          :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}")
      end

      # Controller
      m.template('controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb"))      

      # Tests
      m.template('functional_test.rb', File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))
      m.template('unit_test.rb',       File.join('test/unit', class_path, "#{file_name}_test.rb"))
      m.template('fixtures.yml',       File.join('test/fixtures', "#{table_name}.yml"))

      # Route
      m.route_resources controller_file_name
    end
  end

  protected
  
  def banner
    "Usage: #{$0} resourcefulscaffold ModelName [field:type, field:type]"
  end

  def scaffold_views
    %w[ index show new edit _form ]
  end

  def model_name 
    class_name.demodulize
  end
end
