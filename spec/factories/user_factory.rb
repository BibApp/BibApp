Factory.define(:login_user, :class => User) do |u|
  u.sequence(:login) {|n| "User_#{n}"}
  u.sequence(:email) {|n| "User_#{n}@example.com"}
  u.salt '7e3041ebc2fc05a40c60028e2c4901a81035d3cd'
  u.password 'password'
  u.password_confirmation 'password'
  u.persistence_token ''
  u.after_create { |u| u.activate}
end
