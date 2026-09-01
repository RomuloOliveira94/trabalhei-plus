class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
         :validatable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  # Finds an existing user by the OmniAuth e-mail or creates a new one.
  # OAuth users never use the password form, but Devise requires one,
  # so they get a random secure secret.
  def self.from_omniauth(auth)
    find_or_create_by!(email: auth.info.email) do |user|
      user.name = auth.info.name.presence || auth.info.email
      user.password = SecureRandom.hex(32)
    end
  end
end
