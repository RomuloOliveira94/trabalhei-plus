class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
         :validatable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  has_many :overtimes, dependent: :destroy

  # Finds an existing user by the OmniAuth e-mail or creates a new one.
  # OAuth users never use the password form, but Devise requires one,
  # so they get a random secure secret.
  #
  # The provider must mark the e-mail as verified before it can be linked to
  # an account: otherwise an attacker controlling an unverified address could
  # take over the account that holds it (account takeover via Google OAuth).
  def self.from_omniauth(auth)
    raise OmniAuth::EmailNotVerified unless auth.info.email_verified == true

    find_or_create_by!(email: auth.info.email) do |user|
      user.name = auth.info.name.presence || auth.info.email
      user.password = SecureRandom.hex(32)
    end
  end
end
