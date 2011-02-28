class Keyword < ActiveRecord::Base
  has_many :keywordings
  has_many :works, :through => :keywordings

  # This is necessary because of the common
  # mistake of NOT separating keywords with
  # semicolons in RefWorks/RIS. The result
  # is one long keyword, which oftentimes
  # triggers a PGError from Postgres. I believe
  # MySQL will automatically truncate, but
  # Postgres does not.
  validates_length_of :name, :maximum => 255,
    :message => "of keyword is too long (maximum is 255 characters). Make sure your keywords are separated with semicolons (;)."

  scope :order_by_name, order('name')

end
