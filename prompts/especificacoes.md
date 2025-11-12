# Especificações e prompts

Enunciado (base fornecida em sala)

Partiremos da feature implementada em sala. Essa base já entrega:

- Tela de listagem de metas diárias com estado vazio acolhedor, FAB com microanimação, tip
  bubble e overlay de tutorial (sem sobrepor modais após confirmação).
- Dialog de criação/edição que coleta dados do usuário, aplica validação mínima na UI e retorna
  **a entidade escolhida** pronta.
- Um esqueleto de persistência local conceitual (DTO + armazenamento chave/valor serializado)
  suficiente para conectar as próximas etapas quando evoluirmos do layout‑only para dados reais.

Requisitos principais (contrato)

- Entrada: base existente da feature implementada em sala. Não altere contratos públicos já
  usados pela tela/dialog sem documentar claramente o motivo e o impacto.
- Saída: duas features (IA opcional) e um documento explicativo no repositório. O projeto deve
  compilar (ou, no mínimo, não quebrar contratos/importações existentes) e estar claramente
  documentado.

-------------------------

Planejamento proposto (escopo mínimo a entregar)

Feature A — Progress Overview (obrigatória)
- Objetivo: mostrar um resumo simples do progresso diário/semanais dos hábitos. Deve fornecer
  indicadores que ajudam o usuário a compreender rápido o estado da semana (por exemplo: %
  concluído hoje, streak atual, metas completadas).
- Entrada: lista de hábitos (mesmo formato do armazenamento atual). Pode ler via `PrefsService`.
- Saída: widget reutilizável `ProgressOverview` que recebe uma lista de entidades (habits) e
  calcula métricas básicas.
- Critérios de aceitação:
  - Componente adicionável em `HomePage` sem quebra de contrato.
  - Mostra pelo menos: porcentagem de conclusão hoje e streak máximo atual (calculados a partir
    da estrutura de dados existente ou com heurística temporária se dados faltantes).
  - Código fornecido em `lib/features/progress_overview/` com testes mínimos (opcional).

Feature B — Smart Suggestions (opcional IA)
- Objetivo: sugerir automaticamente 1–3 hábitos iniciais com base em um prompt (local/sem
  integração externa obrigatória). A IA é opcional: pode ser uma implementação heurística.
- Entrada: (opcional) perfil do usuário (nome/email) e histórico mínimo; se não houver, usar
  heurísticas fixas.
- Saída: serviço `SmartSuggestionService` que expõe `Future<List<HabitSuggestion>> suggest(...)`
  e um widget `SmartSuggestionsWidget` que exibe as sugestões e permite ao usuário adicionar uma
  sugestão como novo hábito (reaproveitando `PrefsService.saveHabit`).
- Critérios de aceitação:
  - API do serviço documentada em `prompts/especificacoes.md`.
  - Implementação local (sem chamadas externas) que pode ser trocada por um provedor IA no futuro.

Documentos a incluir no repositório
- `prompts/especificacoes.md` (este arquivo) — contém o enunciado e os contratos das features.
- `docs/apresentacao.md` — descreve a implementação, instruções para rodar, decisões e próximos
  passos.

Notas de implementação
- Preservar contratos existentes (nomes de métodos públicos, caminhos de arquivos usados por
  outras partes do app), preferir criação de novos módulos/arquivos em `lib/features/`.
- Manter mudanças pequenas e facilmente reversíveis (PRs pequenos).
