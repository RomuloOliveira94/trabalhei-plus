# Trabalhei a Mais

Rastreador de horas extras para usuário leigo. Cadastre cada bloco de hora
extra (data, início, fim, descrição), acompanhe o total acumulado do mês e
gere um relatório (PDF/Excel) por período para enviar ao RH.

Rails 8.1 · SQLite · Hotwire (Turbo + Stimulus) · Tailwind · importmap.
Sem Node, sem Redis — Solid Queue/Cache/Cable.

## Funcionalidades

- **Autenticação** — Devise (e-mail/senha) + "Entrar com Google" (OmniAuth).
- **CRUD de horas extras** — criar, editar e apagar (soft delete via Discard).
- **Dashboard** — lista responsiva (tabela no desktop, cards no mobile),
  resumo com total de horas do período, filtro por mês/faixa de data (Ransack).
- **Paginação** — botões no desktop, scroll infinito no mobile.
- **Exportação** — PDF (Prawn) e Excel (Caxlsx) com período selecionável.
- **Turbo Streams** — criar/editar/apagar atualizam a lista sem reload.
- **Mobile** — FAB para "Nova hora extra", filtros em sheet recolhível.
- **pt-BR** — toda a interface em português (i18n), páginas de erro 404/500.

## Como rodar localmente

```sh
bin/setup --skip-server   # instala dependências + prepara o banco
bin/dev                   # servidor + watcher do Tailwind (foreman)
```

Acesse `http://localhost:3000`.

## Testes

```sh
bin/rails db:test:prepare test        # unit + integração (minitest)
bin/rails db:test:prepare test:system # system tests (Capybara + headless Chrome)
bin/ci                                # gate completo (lint + segurança + testes)
```

## Deploy

- Kamal (`config/deploy.yml` é placeholder — ajuste servidor/registry antes
  do primeiro deploy).
- Solid Queue roda dentro do Puma em produção (`SOLID_QUEUE_IN_PUMA=true`).
- Segredos via Rails credentials (`config/master.key` é gitignored).