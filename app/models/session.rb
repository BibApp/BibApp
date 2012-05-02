#This class wraps the table for Rails sessions
#Its purpose is primarily to let us write a portable rake task that will discard old sessions.
class Session < ActiveRecord::Base

end