# TrackHabits — Hábitos Simples

**PRD — Primeira Execução, Consentimento e Identidade**

> **Propósito**: criar e acompanhar hábitos diários com foco em simplicidade e baixo atrito.

---

## Metadados do Projeto

* **Nome do Produto/Projeto**: TrackHabits — Hábitos Simples
* **Responsável**: João Vitor Herzer
* **Curso/Disciplina**: Desenvolvimento de Aplicações (Flutter)
* **Versão do PRD**: v1.0
* **Data**: 2025-10-07

---

## 1) Visão Geral

**Resumo**: TrackHabits ajuda estudantes a criar e acompanhar hábitos diários simples (ex.: beber água). A primeira execução foca em um onboarding muito curto, leitura de políticas e consentimento (LGPD), criação do primeiro hábito e ativação de um lembrete — tudo com identidade visual clara.

**Problemas que ataca**: fricção na primeira configuração, dúvidas sobre privacidade/consentimento, UI carregada.

**Resultado desejado**: primeira experiência guiada e rápida — usuário cria o primeiro hábito (beber água), ativa lembrete e entende políticas; decisões legais são persistidas e fáceis de revogar.

---

## 2) Personas & Cenários de Primeiro Acesso

* **Persona principal**: Estudante universitário com rotina irregular, procura pequenas vitórias diárias.
* **Cenário (happy path)**: abrir app → splash → onboarding (2 telas + consentimento) → visualizar políticas (markdown) → consentir → criar primeiro hábito “Beber água” com lembrete → home mostrando hábito e progresso.
* **Cenários alternativos**:

  * Pular onboarding até consentimento.
  * Escolher não aceitar políticas: fluxo limitado com explicação e possibilidade de aceitar depois.
  * Revogar consentimento nas configurações com confirmação e possibilidade de desfazer (SnackBar).

---

## 3) Identidade do Tema (Design)

### 3.1 Paleta e Direção Visual

* **Primária**: Emerald `#059669`
* **Secundária**: Indigo `#4F46E5`
* **Superfície**: `#FFFFFF`
* **Texto**: `#0F172A`
* Direção: flat minimalista; **useMaterial3: true**; alto contraste (WCAG AA).

### 3.2 Tipografia

* Títulos: `headlineSmall` (peso 600)
* Corpo: `bodyLarge`/`bodyMedium`
* Text scaling suportado (≥ 1.3)

### 3.3 Iconografia & Ilustrações

* Ícones simples (Lucide/Material) em traço consistente.
* **Ícone do app**: ícone simples de **calendário com check** (vetorial, fundo transparente, estilo flat, 1024×1024, sem texto). Paleta: Emerald/Indigo/Surface.
* Hero/empty: ilustração de mesa de estudo / garrafa de água / checklist minimalista.

### 3.4 Prompt para ícone (para gerador)

* "Flat vector circular badge, transparent background, center: calendar page with a checkmark; minimal stroke, slight shadow; palette Emerald #059669, Indigo #4F46E5, Surface #FFFFFF; high contrast; no text; 1024x1024".

---

## 4) Jornada de Primeira Execução (Fluxo Base)

1. **Splash** — exibe logomarca; decide rota por flags/versão de aceite.
2. **Onboarding (2 telas + consentimento)**

   * Tela 1: Bem-vindo — benefício: hábitos simples, 1min para configurar; botões **Avançar** + **Pular**.
   * Tela 2: Como funciona — criar hábito, marcar completado, lembrete rápido; **Avançar/Voltar** + **Pular**.
   * Tela 3 (Consentimento): sem **Pular**; dots ocultos; exige leitura das políticas antes de aceitar.
3. **Policy Viewer** — visualizador Markdown com barra de progresso; botão **Marcar como lido** habilitado somente após 100% do scroll.
4. **Consentimento** — checkbox e botão **Concordo** habilitados após leitura dos dois documentos (Privacidade e Termos).
5. **Criação do 1º hábito (primeiros passos)** — card na Home com CTA: "Criar meu 1º hábito"; template sugerido: **Beber água** com lembrete (ex.: 09:00) e meta "3 copos/dia" (opcional simplificado).
6. **Home** — mostra o hábito com cartão, botão marcar feito (check), progresso diário e opção de editar/remover.
7. **Revogação** — Configurações → Privacidade → Revogar consentimento (AlertDialog + SnackBar com Desfazer).

---

## 5) Requisitos Funcionais (RF)

* **RF‑1**: DotsIndicator sincronizado; oculto na última página do onboarding.
* **RF‑2**: Botões **Pular** levam diretamente ao fluxo de consentimento; **Voltar/Avançar** comportam-se contextualmente.
* **RF‑3**: Visualizador de políticas em Markdown com barra de progresso e botão **Marcar como lido** somente no fim do documento.
* **RF‑4**: Consentimento **opt‑in**: checkbox + ação final habilitados somente após leitura dos 2 documentos.
* **RF‑5**: Splash decide rota por flags/`policies_version_accepted` e `onboarding_completed`.
* **RF‑6**: Fluxo de criação do primeiro hábito: pré‑popular com “Beber água” e sugestão de lembrete.
* **RF‑7**: Revogação com confirmação e **Desfazer** (SnackBar).
* **RF‑8**: Persistir versão das políticas e timestamp de aceite (`policies_version_accepted`, `accepted_at`).
* **RF‑9**: Ícone do app gerado via `flutter_launcher_icons` (PNG 1024×1024).

---

## 6) Requisitos Não Funcionais (RNF)

* **A11Y**: alvos ≥ 48dp, Semantics labels em botões, contraste AA, text scaling 1.3+
* **Privacidade (LGPD)**: logs mínimos; consentimento explícito; opção de revogação fácil.
* **Arquitetura**: **UI → Service → Storage**; **UI não acessa SharedPreferences** diretamente.
* **Performance**: animações ~300ms, leituras de Markdown paginadas/streaming se necessário.
* **Testabilidade**: `PrefsService` mockável; PolicyViewer injetável com conteúdo de fixture.

---

## 7) Dados & Persistência (Chaves sugeridas)

* `privacy_read_v1`: bool
* `terms_read_v1`: bool
* `policies_version_accepted`: string (ex.: `v1`)
* `accepted_at`: string (ISO8601)
* `onboarding_completed`: bool
* `first_habit_created`: bool
* `first_habit_id`: string (UUID)
* `habit_{id}`: objeto serializado (title, goal, reminder_time, enabled)
* `tips_enabled`: bool (opcional)

**Serviço**: `PrefsService` (ou `StorageService`) com métodos: `getBool(key)`, `setBool(key,val)`, `getString`, `setString`, `saveHabit(habit)`, `getHabit(id)`, `deleteHabit(id)`, `isFullyAccepted()` e `migratePolicyVersion(from,to)`.

---

## 8) Roteamento

* `/` → **Splash** (decide)
* `/onboarding` → PageView (2–3 telas)
* `/policy-viewer` → viewer markdown reutilizável
* `/create-habit` → criação rápida de hábito (template: Beber água)
* `/home` → tela inicial
* `/settings/privacy` → revogação/visualizar políticas

---

## 9) Critérios de Aceite

1. Dots sincronizados e ocultos na última tela.
2. **Pular** leva ao consentimento; **Voltar/Avançar** contextuais.
3. PolicyViewer exibe barra de progresso e habilita “Marcar como lido” apenas ao final do scroll.
4. Checkbox e botão final habilitam somente após leitura dos dois docs.
5. Splash direciona para Home quando `policies_version_accepted` existe e `onboarding_completed` true.
6. Revogação funciona com confirmação + SnackBar com Desfazer; sem desfazer → retorno ao fluxo legal.
7. UI nunca acessa `SharedPreferences` diretamente; todas as leituras/escritas via `PrefsService`.
8. Ícone gerado e aplicado em pelo menos uma plataforma.

---

## 10) Protocolo de QA (Testes manuais)

* **Execução limpa**: abrir app clean → onboarding completo → visualizar ambas políticas → aceitar → criar 1º hábito (Beber água) → Home mostra hábito e lembrete.
* **Leitura parcial**: ler apenas 1 das políticas não habiliza checkbox/Concordo.
* **Aceite válido**: após leitura dupla + concordância, persistência de `policies_version_accepted` e `accepted_at`.
* **Reabertura**: app abre direto na Home se políticas aceitas e onboarding completado.
* **Revogação com Desfazer**: revogar → Snackbar Desfazer restaura aceitação.
* **Revogação sem Desfazer**: fluxo volta ao onboarding/consentimento.
* **A11Y**: executar com text scale 1.3, navegação por teclado/semântica.

---

## 11) Riscos & Decisões

* **Risco**: esquecer versionamento do aceite → Mitigação: `policies_version_accepted` + checagem no Splash.
* **Risco**: UI acoplada ao storage → Mitigação: `PrefsService` único, injeção via Provider/GetIt.
* **Decisão**: não esconder elementos desabilitados (acessibilidade).
* **Decisão**: políticas como assets (offline, versionáveis).

---

## 12) Entregáveis

1. PRD preenchido + identidade (paleta, prompt do ícone, moodboard opcional).
2. Implementação do fluxo base (Splash, Onboarding, PolicyViewer, Consentimento, Create Habit, Home) e `PrefsService`.
3. Evidências (prints) dos estados: onboarding, consentimento, criação do 1º hábito, revogação/desfazer.
4. Ícone gerado com `flutter_launcher_icons` e aplicado em pelo menos uma plataforma.

---

## 13) Backlog de Evolução (opcional)

* Tela de Configurações/Privacidade com histórico de aceites.
* Hash por arquivo de política para invalidar aceites quando o conteúdo mudar.
* Reminders inteligentes (snooze, Euler/intervalos)
* Pequenas gamificações (streaks, medalhas) preservando privacidade.

---

## 14) Referências Técnicas

* `dots_indicator` paramétrico
* PageView onboarding com controller e ocultação de dots
* PolicyViewerPage com `Markdown` e Listener de Scroll para calcular progresso
* `PrefsService` central (mockable)
* Splash checando `policies_version_accepted` e `onboarding_completed`

---

## Checklist de Conformidade (colar no PR)

* [ ] Dots sincronizados e ocultos na última tela
* [ ] Pular → consentimento; Voltar/Avançar contextuais
* [ ] PolicyViewer com barra de progresso + “Marcar como lido”
* [ ] Aceite habilita somente após leitura dos 2 docs
* [ ] Splash decide rota por versão aceita
* [ ] Criação do 1º hábito (Beber água) sugerida na Home
* [ ] Revogação com confirmação + Desfazer
* [ ] Sem `SharedPreferences` direto na UI
* [ ] Ícone gerado (calendário com check)
* [ ] A11Y (48dp, contraste, Semantics, text scaling)

---

### Observação ao Aluno

Use este PRD como base: troque identidade e textos conforme seu tema (saúde, finanças, estudos) e mantenha a arquitetura **UI → Service → Storage**. Não esqueça de gerar evidências (prints) e manter chaves de policy version para testes de regressão.

---

*Fim do documento.*
