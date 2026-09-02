# AGENTS.md — trabalheiamais

## Status

Rails 8.1 app, 6 phases shipped on `main` (linear feature stack):

1. **Setup + auth** — Devise (email/senha) + OmniAuth Google (stub), pt-BR locale base, base layout (red/white).
2. **Overtime CRUD** — model with Discard soft delete, responsive index (desktop table / mobile cards), Ransack filters, header summary.
3. **Pagination** — Pagy: desktop buttons + mobile infinite scroll (Turbo Stream sentinel).
4. **Exports** — PDF (Prawn) + Excel (Caxlsx) with period filter; "Usuário" terminology, no email in reports.
5. **Polish + i18n** — full pt-BR i18n, confirm-delete modal (Stimulus `<dialog>`), Turbo Stream CRUD (append/replace/remove), mobile FAB + filter sheet, pt-BR 404/500 pages, a11y (skip link, labels, focus trap).
6. **UI/UX polish + login redesign + PWA + app rename + file naming** — branded sign-in card (login IS the landing at `/`), Google button with official G logo, root route via Devise `authenticated`/`root` (guests → sign-in, signed-in → overtimes), consistent Tailwind styling (red focus rings, hover/transition states, 44px tap targets), mobile-first audit at 375px, pt-BR 404/500 in dev (`consider_all_requests_local = false`), PWA (static `public/manifest.webmanifest` + `public/sw.js` + `public/offline.html`, generated icons), SEO meta tags, product renamed **"Trabalhei +"** (UI text only), new-HE form pre-selects today, and a file-naming sweep (see Conventions).

App module: `Trabalheiamais` (`config/application.rb`). **UI name is "Trabalhei +"** — the Ruby namespace stays `Trabalheiamais` (not renamed, too invasive for v1).

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

- **Root route** — `/` renders the sign-in page for guests (login IS the landing) and the overtime list for signed-in users, via Devise `authenticated :user do root ... end` + a `devise_scope :user` root (see `config/routes.rb`). The unauthenticated root must live inside `devise_scope` so Devise resolves the user mapping.
- **Prod Solid Queue runs inside Puma** (`SOLID_QUEUE_IN_PUMA=true` in `config/deploy.yml`). Do not add a separate worker process.
- Tests use **fixtures** (minitest), no FactoryBot. Parallel workers, `fixtures :all` in `test/test_helper.rb`.
- `bin/setup` auto-launches dev server unless `--skip-server` is passed.
- Secrets via Rails credentials — `config/master.key` is gitignored. Never commit.
- **CD is CapRover, not Kamal** — `.github/workflows/cd.yml` deploys on every push to `main`, but only after polling `ci.yml` for the same SHA and seeing it green (`main` is not branch-protected, so that poll is the only gate). `captain-definition` points CapRover at the `Dockerfile`. Kamal stays for manual deploys and prod access (`bin/kamal console|shell|logs|dbc`), and its `config/deploy.yml` is still placeholder (server `192.168.0.1`, registry `localhost:5555`) — override before using it.
- **CapRover essentials** — repo secrets `CAPROVER_SERVER`, `CAPROVER_APP_NAME`, `CAPROVER_APP_TOKEN` (App Token from the app's Deployment tab). App env: `RAILS_MASTER_KEY` (mandatory), `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` (read from `ENV` in `config/initializers/devise.rb`, *not* credentials), `SOLID_QUEUE_IN_PUMA=true` once jobs exist. Persistent directory `/rails/storage` is mandatory — all four SQLite files live there and every deploy wipes them without it. Health check `/up`, port 80 (Thruster), TLS terminated by CapRover's nginx with `force_ssl`/`assume_ssl` left commented out in `config/environments/production.rb`.
- Dockerfile uses Thruster on :80, entrypoint runs `db:prepare` on boot. Non-root user 1000, jemalloc enabled. The runtime stage installs **`fonts-dejavu-core`** — `Overtimes::Export::Pdf` looks for `DejaVuSans.ttf`/`DejaVuSans-Bold.ttf` under `/usr/share/fonts/truetype/dejavu/` and silently degrades to Prawn's Helvetica (plus an m17n warning per export) if they're missing. Don't drop it.
- i18n: default locale is **pt-BR**, `available_locales` is `[:"pt-BR", :en]` and `fallbacks` is pinned to `[ :en ]`; timezone is **America/Sao_Paulo** (all set in `config/application.rb`).
- **Devise pt-BR comes from the `devise-i18n` gem** — don't hand-write a `devise.pt-BR.yml`. Only the gaps it ships as nil (`devise.shared.minimum_password_length`, `errors.messages.not_saved`) plus app-specific keys live in `config/locales/pt-BR.yml`. The gem's `en` locale covers stock Devise, so there is no `devise.en.yml`.
- **`configure_permitted_parameters` lives in `ApplicationController`** (guarded by `if: :devise_controller?`) and permits `:name` for `:sign_up` and `:account_update`. Any new User attribute exposed through a Devise form must be added there or Devise silently strips it.
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

### File naming (Phase 6 sweep)

Partial and locale-key names must be self-explanatory — no abbreviations or generic words. Renamed in Phase 6:

| Old | New |
|---|---|
| `_overtime_actions.html.erb` / `overtimes.overtime_actions.*` | `_action_buttons.html.erb` / `overtimes.action_buttons.*` |
| `_sentinel.html.erb` / `overtimes.sentinel.*` | `_pagination_sentinel.html.erb` / `overtimes.pagination_sentinel.*` |
| `_summary.html.erb` / `overtimes.summary.*` | `_total_summary.html.erb` / `overtimes.total_summary.*` |
| `_filter_form.html.erb` / `overtimes.filter_form.*` | `_date_filter_form.html.erb` / `overtimes.date_filter_form.*` |

Stimulus controllers (`confirm_modal`, `dialog_modal`, `infinite_scroll`) already describe their action — keep. Auth pages share `devise/shared/_auth_card.html.erb`; relative i18n keys inside `render "partial" do ... end` blocks resolve against the partial path, so use absolute keys there.

## Git + deploy

- Host: GitHub, `RomuloOliveira94/trabalhei-plus`. Work goes **straight to `main`** — no branch/PR flow, no branch protection. Commit locally; the user pushes.
- Deployment target: **CapRover**, via `.github/workflows/cd.yml` (see Gotchas). Kamal's `config/deploy.yml` is kept for manual use and still needs a real server + registry before it works.