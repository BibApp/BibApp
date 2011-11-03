#for each available locale dump the part of config/locales/<locale>.yml that jsperanto needs as JSON into
#public/javascripts/translations
require 'fileutils'
class JsperantoLoadTranslations < Rails::Railtie
  config.after_initialize do
    json_dir = File.join(Rails.root, 'public', 'javascripts', 'translations')
    yaml_dir = File.join(Rails.root, 'config', 'locales')
    FileUtils.mkdir_p(json_dir)
    I18n.available_locales.each do |locale|
      translations = YAML.load_file(File.join(yaml_dir, "#{locale}.yml"))
      json = JSON.pretty_generate(translations[locale.to_s]['jsperanto'])
      File.open(File.join(json_dir, "#{locale}.json"), "w") do |f|
        f.puts(json)
      end
    end
  end
end
