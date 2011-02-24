class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserMailer.signup_notification(user).deliver if user.login != "admin"
  end

  def after_save(user)
    UserMailer.activation(user).deliver if user.recently_activated? and user.login != "admin"
  end
end
