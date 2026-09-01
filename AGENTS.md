# AGENTS.md — trabalheiamais

## Status

Rails 8.1 app, 5 phases shipped on `main` (linear feature stack):

1. **Setup + auth** — Devise (email/senha) + OmniAuth Google (stub), pt-BR locale base, base layout (red/white).
2. **Overtime CRUD** — model with Discard soft delete, responsive index (desktop table / mobile cards), Ransack filters, header summary.
3. **Pagination** — Pagy: desktop buttons + mobile infinite scroll (Turbo Stream sentinel).
4. **Exports** — PDF (Prawn) + Excel (Caxlsx) with period filter; "Usuário" terminology, no email in reports.
5. **Polish + i18n** — full pt-BR i18n, confirm-delete modal (Stimulus `<dialog>`), Turbo Stream CRUD (append/replace/remove), mobile FAB + filter sheet, pt-BR 404/500 pages, a11y (skip link, labels, focus trap).

App module: `Trabalheiamais` (`config/application.rb`).

## Stack

Rails 8.1, Ruby per `.ruby-version`. SQLite everywhere — even production — with multi-DB (primary + Solid Queue/Cache/Cable). Importmap + Hotwire (Turbo + Stimulus). Tailwind via `tailwindcss-rails`. Propshaft for assets.

No node, no esbuild, no Shakapacker. **No Sidekiq/Redis** — Solid Queue (runs inside Puma in prod), Solid Cache, Solid Cable.

## Commands

- `bin/setup --skip-server` — install deps + prepare DB. Default **starts the dev server**; pass `--skip-server` to skip.
- `bin/dev` — foreman-driven dev (`Procfile.dev`: web + `tailwindcss:watch`). May `gem install foreman` globally on first run.
- `bin/rails db:test:prepare test` — required order for minitest. Add `test:system` for system tests.
- `bin/rubocop` — omakase rules via `inherit_gem: rubocop-rails-omakase` (`.rubocop.yml`).
- `bin/ci` — local CI gate (setup + rubocop + brakeman + bundler-audit + importmap audit + tests + db:seed:replant). Sources `config/ci.rb`.
- Security scans: `bin/brakeman --no-pager`, `bin/bundler-audit`, `bin/importmap audit`.
- `bin/rails console` / `bin/jobs` (Solid Queue supervisor).
- `bin/kamal console|shell|logs|dbc` — prod access via Kamal.

## Gotchas

- **No root route** — `/` raises routing error until one is defined in `config/routes.rb` (currently commented out).
- **Prod Solid Queue runs inside Puma** (`SOLID_QUEUE_IN_PUMA=true` in `config/deploy.yml`). Do not add a separate worker process.
- Tests use **fixtures** (minitest), no FactoryBot. Parallel workers, `fixtures :all` in `test/test_helper.rb`.
- `bin/setup` auto-launches dev server unless `--skip-server` is passed.
- Secrets via Rails credentials — `config/master.key` is gitignored. Never commit.
- **Kamal deploy config is placeholder** (`config/deploy.yml`: server `192.168.0.1`, registry `localhost:5555`). Override before first deploy. Volume `trabalheiamais_storage:/rails/storage`.
- Dockerfile uses Thruster on :80, entrypoint runs `db:prepare` on boot. Non-root user 1000, jemalloc enabled.
- i18n only `en`; timezone default UTC (both commented in `config/application.rb`).
- `config/bundler-audit.yml` has placeholder `CVE-THAT-DOES-NOT-APPLY` ignore — clean up later.
- CI: `.github/workflows/ci.yml` runs lint, brakeman, bundler-audit, importmap audit, tests, system tests (screenshot artifact on failure). Dependabot weekly for bundler + github-actions.
- Redis/Valkey service blocks in CI are commented out — don't re-enable, Solid * is the stack.
- `ApplicationController` already uses `allow_browser versions: :modern` + `stale_when_importmap_changes`.

## Testing

Minitest only (no RSpec). Standard Rails layout under `test/` (all dirs empty `.keep` so far).

- Unit/integration: `bin/rails db:test:prepare test`
- System: `bin/rails db:test:prepare test:system` — requires headless Chrome (not bundled; CI uses GH Actions setup).
- Full local gate: `bin/ci`.

## Conventions

Rails 8 omakase defaults apply unless overridden in `config/`. Follow Basecamp conventions (Fat models, thin controllers, concerns for shared behavior, Hotwire-first UX).

## Open questions (ask before building)

- App purpose + primary locale (pt-BR likely from repo name).
- Auth strategy (Devise? Rails 8 `bin/rails generate authentication`? Auth0?).
- Git host + branch/PR/release conventions — none configured yet.
- Deployment target (Kamal placeholder needs real server + registry).