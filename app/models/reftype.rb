class Reftype < ActiveRecord::Base
  set_table_name "reftypes"
  set_primary_key "refworks_id"
  
  has_many :citations
end
