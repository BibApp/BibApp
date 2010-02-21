module AttachmentsHelper

  #determine Asset URL (of asset to which work is attached) based on asset type
  def get_asset_url(asset)
    if asset.kind_of?(Work)
      #return to Work page
      return work_url(asset)
    elsif asset.kind_of?(Person)
      #return to Person page
      return person_url(asset)
    end
  end
end