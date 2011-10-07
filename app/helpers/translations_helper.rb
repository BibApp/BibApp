module TranslationsHelper
  def t_role_name(role_name, opts = {})
    opts.reverse_merge!(:count => 1)
    t("common.roles.#{role_name.downcase}", opts)
  end
end