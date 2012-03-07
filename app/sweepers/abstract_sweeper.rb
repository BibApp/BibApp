class AbstractSweeper < ActionController::Caching::Sweeper

  include CacheHelper

  #common pattern for determining if a cache expiration needs to happen
  #if any of the supplied methods or :destroyed? is true when called on record then return true, else return false
  def trigger_expiration?(record, *methods)
    (methods << :destroyed?).detect {|m| record.send(m)}
  end

end