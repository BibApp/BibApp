class User < ActiveRecord::Base
  has_many :things
  has_one :hat

  before_destroy :ensure_cant_delete_indestructible_user

  protected

  #a completely contrived method to let us test a failed destroy
  def ensure_cant_delete_indestructible_user
    false if self.first_name == 'indestructible'
  end
  
end
