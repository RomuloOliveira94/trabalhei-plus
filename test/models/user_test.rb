require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "name is required" do
    user = User.new(email: "x@example.com", password: "secret123")
    assert_not user.valid?
    assert user.errors.of_kind?(:name, :blank)
  end

  test "name length is bounded" do
    user = User.new(name: "A", email: "x@example.com", password: "secret123")
    assert_not user.valid?
    assert user.errors.of_kind?(:name, :too_short)

    user.name = "A" * 101
    assert_not user.valid?
    assert user.errors.of_kind?(:name, :too_long)
  end

  test "from_omniauth returns the existing user with the same email" do
    auth = OmniAuth::AuthHash.new(info: { name: "Outro Nome", email: users(:one).email, email_verified: true })

    assert_no_difference -> { User.count } do
      assert_equal users(:one), User.from_omniauth(auth)
    end
    assert_equal "Ana Souza", users(:one).reload.name
  end

  test "from_omniauth creates a user with a random password" do
    auth = OmniAuth::AuthHash.new(info: { name: "Google User", email: "google@example.com", email_verified: true })

    user = assert_difference -> { User.count }, 1 do
      User.from_omniauth(auth)
    end

    assert user.persisted?
    assert_equal "Google User", user.name
    assert user.encrypted_password.length >= 60, "expected a bcrypt digest, got a blank/short password"
    assert_not user.valid_password?("password123")
  end

  test "from_omniauth falls back to the email when the name is blank" do
    auth = OmniAuth::AuthHash.new(info: { name: "", email: "noname@example.com", email_verified: true })

    user = User.from_omniauth(auth)
    assert_equal "noname@example.com", user.name
  end

  test "from_omniauth rejects an unverified email (account takeover guard)" do
    auth = OmniAuth::AuthHash.new(info: { name: "Atacante", email: users(:one).email, email_verified: false })

    assert_no_difference -> { User.count } do
      assert_raises(OmniAuth::EmailNotVerified) do
        User.from_omniauth(auth)
      end
    end
  end

  test "from_omniauth rejects a missing email_verified flag" do
    auth = OmniAuth::AuthHash.new(info: { name: "Atacante", email: users(:one).email })

    assert_raises(OmniAuth::EmailNotVerified) do
      User.from_omniauth(auth)
    end
  end
end
