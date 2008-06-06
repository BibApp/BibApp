class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserMailer.deliver_signup_notification(user) if user.login != "admin"
  end

  def after_save(user)
    UserMailer.deliver_activation(user) if user.recently_activated? and user.login != "admin"
  end
end
