module PublishersHelper
  def sherpa_colors
    I18n.t('personalize.sherpa_colors').keys.collect {|k| k.to_s}.sort
  end
end
