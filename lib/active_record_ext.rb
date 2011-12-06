class ActiveModel::Name
  def human_pl(args = {})
    self.human(args.reverse_merge(:count => 2))
  end
end