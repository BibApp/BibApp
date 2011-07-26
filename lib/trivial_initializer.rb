module TrivialInitializer
  def initialize(args = {})
    args.each do |k, v|
      self.send(:"#{k}=", v)
    end
  end
end