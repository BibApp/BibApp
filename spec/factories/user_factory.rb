Factory.define(:unactivated_user, :class => User) do |u|
  u.sequence(:login) {|n| "User_#{n}"}
  u.sequence(:email) {|n| "User_#{n}@example.com"}
  u.password 'password'
  u.password_confirmation 'password'
  u.persistence_token ''
end

Factory.define(:activated_user, :parent => :unactivated_user) do |u|
  u.after_create { |u| u.activate}
end
