module UsersHelper

  def displayable_role(role)
    ['System', 'Group', 'Person'].include?(role.authorizable_type)
  end
end