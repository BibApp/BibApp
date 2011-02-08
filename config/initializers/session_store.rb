# Be sure to restart your server when you modify this file.

Bibapp::Application.configure do
  config.session_store(:active_record_store, :session_key => '_zoom_session',
      :secret => '6ef4f4bba39aae6ef1a1da02e1ace6d8')
end
