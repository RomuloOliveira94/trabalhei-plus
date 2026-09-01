# frozen_string_literal: true

module OmniAuth
  # Raised by User.from_omniauth when the provider did not mark the account
  # e-mail as verified (auth.info.email_verified != true). The callback
  # controller rescues it and shows a friendly pt-BR message instead of
  # signing the user in — linking an unverified address would let an attacker
  # who controls it take over the account that holds it.
  class EmailNotVerified < StandardError
  end
end
