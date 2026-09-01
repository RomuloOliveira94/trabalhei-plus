# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  # --cache false: bin/setup clears tmp/ right before this step, and rubocop's
  # parallel workers then race writing the shared cache (empty/truncated cache
  # files crash ResultCache#load). Disabling the cache makes the step hermetic.
  step "Style: Ruby", "bin/rubocop --cache false"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Assets: Tailwind build", "bin/rails tailwindcss:build"
  step "Tests: Rails", "bin/rails test"
  step "Tests: System", "bin/rails test:system"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: Run system tests
  # step "Tests: System", "bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
