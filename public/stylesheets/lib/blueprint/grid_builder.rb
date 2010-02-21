begin
  require 'rubygems'
  gem 'rmagick'
  require 'rvg/rvg'
rescue Exception => e
end

class GridBuilder < Blueprint
  # included modules
  begin
    include Magick
  rescue
  end


  # properties
  attr_reader :column_width, :gutter_width, :output_path, :able_to_generate
  
  # constructor
  def initialize(options={})
    @able_to_generate = Magick::Long_version rescue false
    return unless @able_to_generate
    @column_width = options[:column_width] || Blueprint::COLUMN_WIDTH
    @gutter_width = options[:gutter_width] || Blueprint::GUTTER_WIDTH
    @output_path  = options[:output_path]  || Blueprint::SOURCE_PATH
  end
  
  # instance methods
  def generate!
    return false unless self.able_to_generate
    total_width = self.column_width + self.gutter_width
    height = 20
    RVG::dpi = 100

    rvg = RVG.new((total_width.to_f/RVG::dpi).in, (height.to_f/RVG::dpi).in).viewbox(0, 0, total_width, height) do |canvas|
      canvas.background_fill = 'white'

      canvas.g do |column|
        column.rect(self.column_width, height).styles(:fill => "#e8effb")
      end

      canvas.g do |baseline|
        baseline.line(0, (height - 1), total_width, (height- 1)).styles(:fill => "#e9e9e9")
      end
    end
    FileUtils.mkdir self.output_path unless File.exists? self.output_path
    rvg.draw.write(File.join(self.output_path, "grid.png"))
  end
end