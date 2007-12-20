module Resourceful
  # We want to define some stuff before we load other modules

  ACTIONS = [:index, :show, :edit, :update, :create, :new, :destroy]
  MODIFYING_ACTIONS = [:update, :create, :destroy]
  PLURAL_ACTIONS = [:index]
  SINGULAR_ACTIONS = ACTIONS - PLURAL_ACTIONS
end

require 'resourceful/default/accessors'
require 'resourceful/default/responses'
require 'resourceful/default/callbacks'
require 'resourceful/default/urls'

module Resourceful::Base
  @@made_resourceful_callbacks = []
  def self.made_resourceful(&block)
    if block
      @@made_resourceful_callbacks << block
    else
      @@made_resourceful_callbacks
    end
  end

  include Resourceful::Default::Accessors
  include Resourceful::Default::Responses
  include Resourceful::Default::Callbacks
  include Resourceful::Default::URLs
end
