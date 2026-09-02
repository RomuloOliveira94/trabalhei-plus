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
| Deploy | CD no [CapRover](https://caprover.com/) via GitHub Actions ([Kamal](https://kamal-deploy.org/) para deploy manual) |

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

## 🚢 Deploy

O deploy contínuo para produção roda no [CapRover](https://caprover.com/), disparado a cada push em `main` (`.github/workflows/cd.yml`). Como aqui o trabalho vai direto para a `main` (sem fluxo de PR e sem branch protection), o gate é o próprio workflow: ele só implanta depois de confirmar que o CI (`.github/workflows/ci.yml`) passou **na mesma revisão** — os 5 jobs (`test`, `system-test`, `lint`, `scan_ruby`, `scan_js`) nunca são pulados nem duplicados, só aguardados. Também dá para disparar um redeploy manual pela aba Actions (`workflow_dispatch`). O `captain-definition` na raiz do repositório aponta o CapRover para o `Dockerfile` existente.

### Segredos do GitHub Actions

Configure em Settings → Secrets and variables → Actions do repositório (nenhum destes vive no código):

| Secret | Valor |
|---|---|
| `CAPROVER_SERVER` | URL do servidor CapRover, ex.: `https://captain.apps.seu-dominio.com` |
| `CAPROVER_APP_NAME` | Nome do app cadastrado no CapRover |
| `CAPROVER_APP_TOKEN` | Token de deploy do app |

Para gerar o token: na aba **Deployment** do app no painel do CapRover, clique em **Enable App Token** e copie o valor gerado.

### Variáveis de ambiente do app no CapRover

Em **App Configs** → **Environmental Variables**, configure:

| Variável | Obrigatória? | Para quê |
|---|---|---|
| `RAILS_MASTER_KEY` | **Sim** | Decripta `config/credentials.yml.enc` em runtime (é o mesmo valor de `config/master.key`, que não está no repositório). Sem ela o container sobe e derruba na inicialização. |
| `GOOGLE_CLIENT_ID` | Para o "Entrar com Google" | Lida de `ENV` em `config/initializers/devise.rb` (**não** das credentials). Em branco, o botão aparece mas o fluxo OAuth falha; o login por e-mail/senha continua funcionando. |
| `GOOGLE_CLIENT_SECRET` | Para o "Entrar com Google" | Idem — par do `GOOGLE_CLIENT_ID` (veja `.env.example`). |
| `SOLID_QUEUE_IN_PUMA` | **Sim** | Defina como `true` desde o primeiro deploy. Sobe o supervisor do Solid Queue dentro do Puma (`config/puma.rb`) — é assim que esta app roda jobs em produção, sem processo worker separado (o `config/deploy.yml` já define `true`). Sem ela, qualquer `deliver_later`/`perform_later` que venha a existir fica enfileirado e nunca executa. |
| `RAILS_LOG_LEVEL` | Não | Padrão `info` (`config/environments/production.rb`). |

### Volume persistente (obrigatório)

O app usa SQLite para o banco principal **e** para Solid Queue, Solid Cache e Solid Cable (veja `config/database.yml`) — os quatro arquivos `.sqlite3` ficam em `storage/`, o que resolve para `/rails/storage` dentro do container (`WORKDIR /rails` no `Dockerfile`).

**Sem um volume persistente mapeado em `/rails/storage`, cada deploy apaga todos os usuários e todas as horas extras cadastradas.** Configure em **App Configs** → **Persistent Directories**:

| Caminho no container | Rótulo (label) |
|---|---|
| `/rails/storage` | ex.: `trabalheiamais-storage` |

O `bin/docker-entrypoint` roda `db:prepare` a cada boot, então o primeiro deploy cria e migra os quatro bancos sozinho.

### Health check

Configure o health check do CapRover para consultar `/up` — a rota padrão do Rails 8 (`rails/health#show`), já registrada em `config/routes.rb`.

### Porta e TLS

O `Dockerfile` expõe a porta `80` (`EXPOSE 80`, servida pelo Thruster), que já é o padrão do CapRover — nenhuma configuração extra de porta é necessária. O CapRover termina o TLS no próprio Nginx e encaminha HTTP simples para o container; como `config.force_ssl` e `config.assume_ssl` seguem comentados em `config/environments/production.rb`, isso não causa loop de redirecionamento. Se um dos dois for ativado no futuro, o outro precisa ser ativado junto.

### Acesso à produção

A produção roda no CapRover, então o acesso ao app passa por ele:

- **Logs**: painel do CapRover → o app → aba **App Logs**.
- **Console / shell**: no host do CapRover, `docker exec -it $(docker ps -qf name=srv-captain--<app>) bin/rails console` (troque `<app>` pelo nome do app; use `bin/rails dbconsole` ou `bash` no lugar de `bin/rails console` conforme a necessidade).

### Deploy manual (Kamal)

O Kamal continua no `Gemfile` e o `config/deploy.yml` segue versionado para um deploy gerenciado pelo próprio Kamal, separado do CapRover. Os valores de servidor e registry ainda são placeholders — ajuste antes de usar. Os comandos `bin/kamal console|shell|logs|dbc` só enxergam containers publicados pelo Kamal; eles **não** alcançam o deploy do CapRover, cujos containers se chamam `srv-captain--<app>`.

## 📄 Licença

Distribuído sob a licença **MIT**.