class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserMailer.signup_notification(user).deliver unless user.email == "admin@example.com"
  end

  def after_save(user)
    UserMailer.activation(user).deliver if user.recently_activated? and user.email != "admin@example.com"
  end
end
