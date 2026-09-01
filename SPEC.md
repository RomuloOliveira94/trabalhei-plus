# SPEC — Trabalhei +

> **Nota (Phase 6):** o nome do produto mudou de "Trabalhei a Mais" para
> "Trabalhei +". Este documento foi atualizado; o nome antigo está
> superseded e só permanece no histórico de commits. O módulo Ruby
> `Trabalheiamais` (namespace interno) não foi renomeado.

> Rastreador de horas extras para usuário leigo. Rails 8.1 · SQLite · Hotwire.

---

## 1. Visão do produto

**Problema.** Funcionários que fazem horas extras perdem o controle do tempo e do valor a receber porque anotam em papel, planilha avulsa ou memória, e na hora de cobrar do RH não conseguem comprovar nada de forma organizada.

**Solução.** App web minimalista (login + CRUD) onde o usuário cadastra cada bloco de hora extra com data, hora de início, hora de fim e descrição, acompanha o total acumulado do mês no dashboard, e gera um relatório (PDF/Excel) por período para enviar ao RH.

**Não-objetivo.** Substituir sistema de folha/ponto da empresa. Não há integração com relógio, gestor ou RH — o usuário é o próprio auditor do próprio tempo.

---

## 2. Persona & fluxo principal

**Persona.** Funcionário CLT/PJ brasileiro, sem familiaridade técnica, que faz horas extras eventuais (não é rotina). Usa o celular na maior parte do tempo. Precisa de algo tão simples quanto "anotar no papel", mas que renda um documento apresentável.

**Fluxo principal.**
1. Primeiro acesso → tela de cadastro (nome completo + e-mail + senha) ou "Entrar com Google".
2. Login → dashboard do mês corrente já carregado, com total de horas no topo e lista vazia (ou com as HEs já cadastradas).
3. Toque em "Nova HE" (FAB no mobile / botão no desktop) → modal/form com data, início, fim, descrição.
4. Lista mostra a HE imediatamente (Turbo Stream) — tabela no desktop, cards no mobile.
5. Usuário revisa o resumo do mês, edita ou apaga conforme necessário.
6. Fim do mês (ou quando quiser) → clica em "Exportar" → escolhe PDF ou Excel → seleciona período (padrão: mês corrente) → baixa arquivo → envia ao RH.

---

## 3. Escopo funcional

### Autenticação
- **Devise** com módulos `database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable`.
- **OmniAuth Google** via `omniauth-google-oauth2` como provider alternativo ao email/senha.
- Cadastro exige **nome completo** (campo `name` no User) — sem aprovação, sem e-mail corporativo.
- Sessão scoped: cada usuário só vê/edita/apaga as próprias HEs.

### CRUD de Hora Extra (Overtime)
- Campos: `start_at` (datetime), `end_at` (datetime), `description` (text, obrigatório, máx. ~500 chars).
- Criar, listar, editar e apagar a qualquer momento após o login.
- Sem status (rascunho/aprovado) — toda HE é imediatamente "definitiva" para o usuário.

### Dashboard / Index
- Rota raiz autenticada.
- Lista responsiva: **tabela no desktop** (≥ md), **cards no mobile** (< md).
- Colunas/campos visíveis: data, horário (início → fim), duração, descrição (truncada), ações (editar/apagar).
- **Resumo no topo**: total de horas acumuladas no mês corrente, em destaque.

### Edição e exclusão
- Edição abre mesmo form (ou página) usado na criação, pré-preenchido.
- Delete sempre via **alerta de confirmação** (modal Stimulus/Turbo), sem delete acidental por toque duplo.
- Política de delete: ver regra em §5.

### Filtros
- **Filtro padrão** ao abrir o dashboard: mês e ano correntes.
- Navegação mês a mês (botões ‹ ›) e seletor de mês/ano.
- **Ransack** para filtros adicionais (busca na descrição, faixa de data customizada, etc.).
- Filtro customizado de período: data início + data fim (case "Exportar" usa esse range).

### Paginação
- **Mobile (< md):** scroll infinito — carrega próxima página ao chegar no fim da lista (Turbo Frame + Stimulus IntersectionObserver).
- **Desktop (≥ md):** paginação tradicional com botões (primeira / anterior / páginas / próxima / última).
- Mesmo backend, duas UIs condicionadas por breakpoint.

### Exportação
- **PDF** e **Excel**, gerados sob demanda (não agendado).
- Conteúdo do relatório, por HE: data, horário de início, horário de fim, duração, descrição.
- **Total de horas no fim do documento**.
- **Período selecionável** (não limitado a um mês) — defaults para mês corrente; usuário pode expandir.
- Header do relatório: nome do usuário, e-mail, período selecionado, data de emissão.
- Filename: `horas-extras_<nome>_<de>_a_<ate>.<ext>`.

---

## 4. Fora do escopo (v1)

Listado explicitamente para evitar scope creep:

- Notificações (push, e-mail, lembrete de bater ponto).
- Multi-tenant / multi-empresa.
- Aprovação por gestor / workflow de validação.
- Anexos (foto do ponto, atestado, PDF importado).
- Edição em massa.
- Multi-idioma (apenas pt-BR).
- Dark mode (apenas tema claro).
- Exportação agendada / recorrente.
- Integração com relógio de ponto, ERP ou folha de pagamento.
- Campos extras por HE: projeto, cliente, local, tipo de hora extra (50%/100%), centro de custo.
- API pública / webhook.
- App mobile nativo.

---

## 5. Regras de negócio & validações

Valores com asterisco (*) são **decisões propostas** — ver §10 antes de implementar.

| # | Regra | Valor proposto |
|---|---|---|
| R1 | `end_at > start_at` | obrigatório, hard validation |
| R2 | Duração mínima por HE | **\>= 5 minutos*** (evita zero/click acidental) |
| R3 | Duração máxima por HE | sem limite (turno 12h+ é possível) |
| R4 | Sobreposição entre HEs do mesmo usuário | **permitir sem warning*** (usuário pode ter dois blocos no mesmo dia) |
| R5 | HE no futuro (`start_at > agora`) | **permitir*** (usuário pode planejar) |
| R6 | HE antiga (sem limite retroativo) | permitir (ex: esqueceu de anotar semana passada) |
| R7 | Timezone de armazenamento | UTC (padrão Rails) |
| R8 | Timezone de exibição | `Brasilia` (UTC-3) por padrão***; ajustável por usuário em versão futura |
| R9 | Quem vê/edita/apaga cada HE | **somente o dono** (`current_user.overtimes`) |
| R10 | Delete | **soft delete** (`deleted_at`)*** — preserva histórico para auditoria e recuperação acidental |
| R11 | Listagens e exports | filtram por `deleted_at: nil` |
| R12 | Formato de horas no resumo/UI | **`10,5h`** (decimal com vírgula, locale pt-BR) |
| R13 | Formato de horas no export (PDF/Excel) | **`10:30`** (HH:MM, formal/RH) |
| R14 | Descrição obrigatória | sim |
| R15 | `description` tamanho máximo | 500 caracteres |
| R16 | Login com Google exige domínio específico | **não** — qualquer Google Account (v1 simples) |

---

## 6. Critérios de aceite (Given/When/Then)

### AC-1 · Cadastro de HE
**Given** usuário autenticado no dashboard
**When** clica em "Nova HE", preenche data, `start_at`, `end_at` (válidos), descrição
**Then** HE aparece na lista sem reload (Turbo Stream)
**And** total de horas do mês é recalculado e exibido no topo
**And** filtro continua no mês corrente

### AC-2 · Edição de HE
**Given** HE existente na lista
**When** usuário clica em "Editar", altera `end_at`
**Then** lista reflete novo valor imediatamente
**And** total de horas do mês é recalculado

### AC-3 · Delete de HE (com confirmação)
**Given** HE existente na lista
**When** usuário clica em "Apagar" e confirma no modal
**Then** HE some da lista
**And** total de horas do mês é recalculado
**And** HE permanece no banco com `deleted_at` preenchido (soft delete)

### AC-4 · Filtro de mês
**Given** dashboard aberto
**When** usuário clica em "‹" ou "›" (navegação de mês)
**Then** lista filtra HEs do mês selecionado
**And** resumo do topo mostra total do mês selecionado
**And** URL reflete o mês (`?month=YYYY-MM` ou via Ransack)

### AC-5 · Filtro de período customizado
**Given** dashboard aberto
**When** usuário define data início e data fim (Ransack)
**Then** lista filtra HEs dentro do range
**And** resumo do topo mostra total do range (não mais do mês)

### AC-6 · Export PDF
**Given** dashboard aberto (ou tela de export dedicada)
**When** usuário escolhe "Exportar PDF" e confirma período (padrão: mês corrente)
**Then** download de arquivo `.pdf` inicia
**And** PDF contém: header (nome/e-mail/período/emissão), tabela com data/início/fim/duração/descrição de cada HE, linha de total
**And** filename: `horas-extras_<nome-slug>_<de>_a_<ate>.pdf`

### AC-7 · Export Excel
**Given** mesmo contexto do AC-6
**When** usuário escolhe "Exportar Excel"
**Then** download de `.xlsx` inicia com planilha equivalente (mesmas colunas, total na última linha)

### AC-8 · Paginação mobile (scroll infinito)
**Given** usuário em viewport mobile (< md) com mais HEs que cabem na primeira página
**When** rola até o fim da lista
**Then** próxima página carrega automaticamente (sem clique)
**And** nenhuma página de botões é renderizada

### AC-9 · Paginação desktop (botões)
**Given** usuário em viewport desktop (≥ md) com mais HEs que cabem na primeira página
**When** visualiza a lista
**Then** vê botões "Primeira / Anterior / 1 2 3 / Próxima / Última"
**And** clicar em página recarrega apenas a lista (Turbo Frame)

### AC-10 · Login com Google
**Given** usuário não autenticado
**When** clica em "Entrar com Google" e autoriza no popup
**Then** callback cria/vincula User com `name` e `email` do Google
**And** usuário é redirecionado ao dashboard autenticado

### AC-11 · Login email/senha
**Given** usuário não autenticado
**When** submete email + senha válidos
**Then** sessão é criada e dashboard é exibido

### AC-12 · Scoping por usuário
**Given** usuário A autenticado
**When** acessa `/overtimes` ou tenta editar/apagar HE de outro usuário (via URL direta)
**Then** só vê HEs próprias
**And** ação em HE de outro retorna 404 (ou 403 — definir em impl)

---

## 7. Stack técnica (fixa)

Tudo já no `Gemfile` da omakase, exceto gems novas marcadas com **\[+\]**.

| Camada | Tecnologia | Notas |
|---|---|---|
| Framework | Rails `~> 8.1.3` | omakase defaults |
| Ruby | per `.ruby-version` | já pinned |
| DB | SQLite + multi-DB (primary + Solid Queue/Cache/Cable) | AGENTS.md fixa |
| Assets | importmap + Hotwire (Turbo + Stimulus) | sem Node/esbuild |
| CSS | Tailwind via `tailwindcss-rails` | tema claro |
| Asset pipeline | Propshaft | |
| Auth | Devise **\[+\]** | email/senha |
| OAuth | `omniauth-google-oauth2` **\[+\]** | provider Google |
| Filtro/busca | Ransack **\[+\]** | query string params |
| Paginação | **Pagy** **\[+\]*** | suporta infinite scroll + botões |
| PDF | **Prawn** + `prawn-table` **\[+\]*** | Ruby puro, sem Chrome |
| Excel | `caxlsx` + `caxlsx_rails` **\[+\]*** | .xlsx |
| Jobs/Cache/Cable | Solid Queue / Solid Cache / Solid Cable | já inclusos |
| Testes | Minitest + fixtures + Capybara | sem FactoryBot, sem RSpec |
| Lint/Segurança | Rubocop omakase + Brakeman + bundler-audit + importmap audit | `bin/ci` |

*Itens com `*` são decisões propostas — ver §10.

---

## 8. UI/UX

### Identidade visual
- **Tema:** claro (light only na v1).
- **Cor primária:** vermelho (proposta: `#DC2626` — red-600 do Tailwind).
- **Fundo:** branco.
- **Acentos neutros:** gray-50/100 para superfícies, gray-900 para texto.
- **Tipografia:** sans-serif do sistema (Tailwind default).
- **Estilo:** minimalista, sem sombras pesadas, sem gradientes, sem ilustrações decorativas.

### Layout responsivo (mobile-first)

**Mobile (< md):**
- Header fixo: logo "Trabalhei +" + avatar/menu do usuário.
- **Bottom navbar** com 3 destinos: Início, Nova (central, destacado), Exportar.
- **FAB** ("+") flutuante no canto inferior direito para "Nova HE" (atalho extra).
- Lista em **cards** verticais, um por HE, com ações inline (ícones).
- Filtros em **bottom sheet** (abre ao tocar no chip de mês).
- Modal de confirmação de delete centralizado.

**Desktop (≥ md):**
- Header com logo à esquerda e user menu à direita.
- Sidebar removida — filtros **inline** no topo da página.
- Botão "Nova HE" no canto superior direito da lista.
- Lista em **tabela** com colunas: Data · Início · Fim · Duração · Descrição · Ações.
- Paginação por botões logo abaixo da tabela.
- Modal de confirmação de delete centralizado (mesmo componente).

### Componentes compartilhados
- `<turbo-frame id="overtime_list">` para paginação sem reload.
- Stimulus controllers: `clipboard` (se aplicável), `confirm-dialog`, `infinite-scroll`.
- Ícones via inline SVG (sem gem adicional) ou `lucide-rails` **\[?\]**.

---

## 9. Esquema de dados (resumo)

### `users` (Devise)
| Campo | Tipo | Notas |
|---|---|---|
| `id` | bigint | PK |
| `email` | string | unique, required |
| `encrypted_password` | string | Devise |
| `name` | string | **required** (cadastro) |
| `provider` | string | nullable, OmniAuth |
| `uid` | string | nullable, OmniAuth |
| `remember_created_at` | datetime | Devise |
| `reset_password_sent_at` | datetime | Devise |
| timestamps | | |

> Confirmação de e-mail (`confirmable`) **desabilitada na v1** (fricção para usuário leigo).

### `overtimes`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | bigint | PK |
| `user_id` | bigint | FK → users, indexed, NOT NULL |
| `start_at` | datetime | NOT NULL |
| `end_at` | datetime | NOT NULL |
| `description` | text | NOT NULL, max 500 |
| `deleted_at` | datetime | nullable (soft delete) |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Índices propostos:**
- `index_overtimes_on_user_id`
- `index_overtimes_on_user_id_and_start_at` (range queries por mês)
- `index_overtimes_on_user_id_and_deleted_at` (filtro padrão)

**Campos opcionais considerados e rejeitados na v1:** `project`, `location`, `hour_type` (50%/100%), `attachments`.

---

## 10. Perguntas em aberto / decisões pendentes

Cada item lista a decisão proposta em **bold**; aceitar = seguir o proposto, responder = ajustar.

| # | Pergunta | Proposta |
|---|---|---|
| Q1 | Setup de remote GitHub? | **Sem remote agora**; criar personal repo ao final da fase (e). |
| Q2 | `config.i18n.default_locale` = `:pt-BR` e arquivo `config/locales/pt-BR.yml`? | **Sim**, ativar i18n pt-BR desde o início. |
| Q3 | Validação de overlap entre HEs do mesmo usuário? | **Não bloquear** (R4 — permite dois blocos no mesmo dia). |
| Q4 | HE no futuro é permitida? | **Sim, sem limite** (R5). |
| Q5 | Soft delete ou hard delete? | **Soft delete** com `deleted_at` (R10). |
| Q6 | Timezone default do app? | **Brasilia (UTC-3)** para exibição; UTC no storage. |
| Q7 | Formato de horas no resumo/UI? | **`10,5h`** decimal pt-BR. |
| Q8 | Formato de horas no export? | **`10:30`** HH:MM. |
| Q9 | Pagy ou Kaminari? | **Pagy** (mais leve, suporte nativo a infinite scroll). |
| Q10 | Prawn ou Grover para PDF? | **Prawn** (sem Chrome, deploy mais simples). |
| Q11 | Credenciais Google OAuth agora? | **Stub com placeholders** em `credentials.yml.enc`; creds reais quando tiver domínio. |
| Q12 | Hostname do app em prod? | Placeholder `trabalheiamais.example.com`; afeta callback URL. |
| Q13 | Duração mínima de HE? | **5 minutos** (R2). |
| Q14 | Lembrar e-mail após cadastro (auto-login)? | **Sim** — Devise já faz com `confirmable` desabilitado. |
| Q15 | Nome completo como campo único ou nome + sobrenome? | **Campo único** `name` (string livre) para reduzir fricção. |

> Se todas as propostas forem aceitas sem ressalva, responder **"ok em todas"** é suficiente para iniciar a fase (a).

---

## 11. Plano de entrega sugerido

Sem datas. Cada fase entrega valor testável de ponta a ponta.

- **(a) Setup + auth** — adicionar gems (Devise, OmniAuth Google, Ransack, Pagy, Prawn, Caxlsx), gerar `User`, configurar Devise + OmniAuth, telas de login/cadastro/logout, layout base (header + bottom nav mobile), `ApplicationController#allow_browser` já existente preservado, i18n pt-BR, fixtures de User.
- **(b) CRUD Hora Extra + index responsivo** — model `Overtime` + migration, validações (R1, R2, R14, R15), controller com `current_user.overtimes`, views new/edit (compartilhada via partial) + index responsivo (tabela desktop / cards mobile), Turbo Streams para create/update/destroy, modal de confirmação de delete.
- **(c) Filtros + resumo** — filtro padrão mês/ano, navegação ‹›, Ransack para período customizado e busca na descrição, card de resumo no topo (total do mês), helper de formatação de horas.
- **(d) Paginação mobile/desktop** — Pagy integrado, dois partials de paginação (botões desktop / sentinel mobile), Stimulus controller de IntersectionObserver para infinite scroll, breakpoint gate via Stimulus values ou CSS-only.
- **(e) Export PDF/Excel** — services `OvertimeReport::Pdf` e `OvertimeReport::Excel`, controller `ExportsController` com endpoint de download, tela/bottom-sheet de seleção de período, header com nome/e-mail/período, linha de total no fim.
- **(f) Polish + i18n** — revisão de UX (FAB, empty states, loading), passar todas as strings por `t(...)`, smoke test de todos os fluxos no `bin/ci`, brakeman + bundler-audit limpos.

> A ordem é sequencial por dependência (b depende de a, c de b, etc.) mas as fases (a)→(b)→(c) já entregam um MVP utilizável.

---

## Apêndice · Referências do repo

- `AGENTS.md` — status greenfield, stack pinned, comandos (`bin/setup --skip-server`, `bin/dev`, `bin/ci`, etc.).
- `Gemfile` — Rails 8.1, SQLite, Solid Queue/Cache/Cable, importmap, Hotwire, Tailwind, Propshaft. Sem Devise/OmniAuth/Ransack/Pagy/Prawn/Caxlsx ainda.
- `config/application.rb` — `config.load_defaults 8.1`; i18n e timezone comentados (a ativar na fase a/f).
- `config/routes.rb` — vazio (raiz ainda não definida, comentado). Auth e resources entram na fase a/b.
