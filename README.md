<div align="center">

# ⏱️ Trabalhei +

### Rastreador de horas extras simples e direto — cadastre, acompanhe o total do mês e exporte relatórios em PDF ou Excel.

[![Ruby](https://img.shields.io/badge/Ruby-4.0.2-CC342D?logo=ruby&logoColor=white)](.ruby-version)
[![Rails](https://img.shields.io/badge/Rails-8.1-CC0000?logo=rubyonrails&logoColor=white)](Gemfile)
[![SQLite](https://img.shields.io/badge/SQLite-003B57?logo=sqlite&logoColor=white)](Gemfile)
[![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-FF4D4D?logo=hotwire&logoColor=white)](Gemfile)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?logo=tailwindcss&logoColor=white)](Gemfile)
[![Devise](https://img.shields.io/badge/Devise-986DFF?logo=rubygems&logoColor=white)](Gemfile)
[![Minitest](https://img.shields.io/badge/Minitest-0FAAFF?logo=rubygems&logoColor=white)](Gemfile)
[![PWA](https://img.shields.io/badge/PWA-ready-5A0FC8?logo=pwa&logoColor=white)](public/manifest.webmanifest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

---

## 🎉 Sobre

**Trabalhei +** é um rastreador de horas extras pensado para o usuário leigo: cadastre cada bloco de hora extra (data, início, fim e descrição), acompanhe o total acumulado do mês e gere um relatório (PDF/Excel) por período para enviar ao RH.

Sem Node, sem Redis — Rails 8.1 com SQLite e importmap mantém o setup local extremamente simples.

## ✨ Funcionalidades

- 📋 **CRUD de horas extras** — criar, editar e apagar (soft delete via Discard).
- 🔐 **Autenticação** — Devise (e-mail/senha) + "Entrar com Google" (OmniAuth).
- 📊 **Dashboard** — lista responsiva (tabela no desktop, cards no mobile), resumo com total de horas do período e filtro por mês/faixa de data (Ransack).
- 📄 **Exportação** — PDF (Prawn) e Excel (Caxlsx) com período selecionável.
- ⚡ **Turbo Streams** — criar/editar/apagar atualizam a lista sem reload.
- 📱 **Mobile** — FAB para "Nova hora extra", filtros em sheet recolhível e scroll infinito.
- 🎨 **PWA** — instalável (manifest + service worker), página offline e ícones gerados.
- 🇧🇷 **pt-BR** — toda a interface em português (i18n), com páginas de erro 404/500.

## 🛠️ Tecnologias

| Camada | Tecnologia |
|---|---|
| Backend | [Ruby on Rails 8.1](https://rubyonrails.org/) |
| Autenticação | [Devise](https://github.com/heartcombo/devise) + OmniAuth Google |
| Frontend reativo | [Hotwire](https://hotwired.dev/) — Turbo + Stimulus |
| Banco de dados | SQLite |
| Filas de background | [Solid Queue](https://github.com/rails/solid_queue) |
| Cache | [Solid Cache](https://github.com/rails/solid_cache) |
| WebSockets (Action Cable) | [Solid Cable](https://github.com/rails/solid_cable) |
| Assets JS | Importmap (sem Node/Webpack) |
| CSS | Tailwind CSS |
| Testes | Minitest + Capybara (headless Chrome) |
| Deploy | [Kamal](https://kamal-deploy.org/) |

## 🚀 Como rodar localmente

### Pré-requisitos

- Ruby **4.0.2** (veja [`.ruby-version`](.ruby-version); recomendado usar [rbenv](https://github.com/rbenv/rbenv) ou [asdf](https://asdf-vm.com/))
- SQLite3

### Setup

```bash
git clone https://github.com/RomuloOliveira94/trabalhei-plus.git
cd trabalhei-plus
bin/setup --skip-server
```

O `bin/setup` instala as gems e prepara o banco de dados. Se quiser já subir o servidor local, rode `bin/setup` sem a flag.

### Rodando o servidor

```bash
bin/dev
```

Isso sobe, via [Foreman](https://github.com/ddollar/foreman) (`Procfile.dev`), o servidor Rails e o watcher do Tailwind ao mesmo tempo. Acesse **http://localhost:3000**.

### Testes

```bash
bin/rails db:test:prepare test        # unit + integração (minitest)
bin/rails db:test:prepare test:system # system tests (Capybara + headless Chrome)
bin/ci                                # gate completo (lint + segurança + testes)
```

## 📸 Screenshots

> Em breve — capturas de tela do dashboard, do formulário de horas extras e das exportações.

## 🤝 Como contribuir

1. Faça um **fork** do repositório.
2. Crie uma branch a partir da `main`: `git checkout -b minha-feature`.
3. Faça suas alterações seguindo as convenções do projeto (veja `AGENTS.md` para arquitetura e padrões).
4. Antes de abrir o PR, rode as checagens que também rodam no CI (`.github/workflows/ci.yml`):

   ```bash
   bin/rubocop -f github     # lint (rubocop-rails-omakase)
   bin/brakeman --no-pager   # análise estática de segurança
   bin/bundler-audit         # auditoria de dependências
   bin/importmap audit       # audita dependências JS pinadas
   ```

5. Abra um **Pull Request** descrevendo o que mudou e por quê.

## 📄 Licença

Distribuído sob a licença **MIT**.