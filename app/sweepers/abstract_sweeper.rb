class AbstractSweeper < ActionController::Caching::Sweeper

  include CacheHelper

  #common pattern for determining if a cache expiration needs to happen
  #if any of the supplied methods or :destroyed? is true when called on record return true, else return false
  def trigger_expiration?(record, *methods)
    (methods << :destroyed?).detect {|m| record.send(m)}
  end

  #if the given record and methods should cause a cache expiration as determined by trigger_expiration?
  #then yield to the block, which should compute the relevant ids and return an array (returned as is), a false value
  #(returned as an empty array), or a single id (returned as a one element array)
  #if not then return an empty array
  def expired_ids(record, *methods)
    if trigger_expiration?(record, *methods)
      ids = yield
      ids.is_a?(Array) ? ids : (ids ? [ids] : [])
    else
      []
    end
  end

end