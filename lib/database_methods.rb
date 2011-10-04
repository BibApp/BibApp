#methods to help with database interaction
module DatabaseMethods

  module_function

  #return like operator that is case insensitive - depends on database
  def case_insensitive_like_operator
    ActiveRecord::Base.connection.adapter_name == 'PostgreSQL' ? 'ILIKE' : 'LIKE'
  end

end