# Apresentação da entrega

Este documento reúne a documentação obrigatória solicitada para a entrega principal.

## Sumário executivo (máx. 1 página)

O projeto entregue é uma aplicação Flutter com duas features principais propostas e
com implementações iniciais (stubs e widgets):

- Progress Overview: widget que apresenta um resumo visual do progresso do usuário
  (marcação diária/semana) e métricas básicas.
- Smart Suggestions: serviço e widget que retornam sugestões de hábitos iniciais. A
  implementação atual é local (stub) e preparada para fácil substituição por um
  serviço de IA/endpoint remoto no futuro.

Resultados: estrutura do código organizada em `lib/features/*`, documentação básica de
especificação em `prompts/especificacoes.md` e um `README`/scripts básicos para rodar
o app. As features estão testáveis localmente e prontas para extensão.

## Arquitetura e fluxo de dados

Arquitetura (resumo): camada de UI (widgets) → camada de domínio/serviços (features) →
persistência local (por enquanto não implementada) / serviços externos (IA) opcional.

Diagrama simples (ASCII):

  [UI Widgets]
       |
       v
  [Feature Services]
   |           \
   v            v
 [Local Storage] [IA / External API]

Onde a IA entra no fluxo (se usada):
- Inputs: perfil do usuário (idade, hábitos atuais, preferências), histórico de
  marcações (se disponível), prompts para gerar sugestões.
- Outputs: lista de sugestões rankeadas (texto), metadata (confiança, tags).

Atualmente a integração com IA não está ativa — `Smart Suggestions` funciona como stub
local que devolve sugestões fixas. O código está organizado para substituir esse stub por
uma chamada HTTP/SDK para um modelo de IA sem mudanças nas camadas de UI.

## Features implementadas

A seguir, para cada feature que existe neste repositório, há objetivo, exemplos e
instruções de teste.

### 1) Progress Overview

Objetivo
- Apresentar ao usuário um resumo do progresso (hoje / últimos 7 dias / streaks) de
  forma clara e imediata.

IA usada?
- Não. Implementação local baseada em cálculos sobre dados de marcação (stub).

Exemplos de entrada e saída (3 casos):
- Caso A — Usuário sem histórico
  - Entrada: [] (nenhuma marcação)
  - Saída: cartão com "Nenhum dado" e sugestões para começar
- Caso B — Usuário com 3 marcações nos últimos 7 dias
  - Entrada: [2025-11-08, 2025-11-10, 2025-11-11]
  - Saída: resumo: 3/7 dias, streak atual 1 dia, gráfico pequeno com pontos
- Caso C — Usuário com histórico frequente
  - Entrada: marcações diárias nos últimos 30 dias
  - Saída: resumo: 30/30, streak 30, medalha de progresso e gráfico com tendência

Como testar localmente (passo a passo)
1. No diretório do projeto, instale dependências:

```powershell
flutter pub get
```

2. Abra o app no modo debug:

```powershell
flutter run
```

3. Navegue até a tela que contém o `ProgressOverview` (ex.: tela principal). Para simular
   diferentes entradas, altere o stub de dados em `lib/features/progress_overview/` ou
   adicione marcações de teste no local storage simulada.

Limitações e riscos
- Sem persistência real, os cálculos são apenas demonstrativos. Com dados reais, é
  preciso validar desempenho e corretude de cálculos de streaks.

Código gerado pela IA (se aplicável)
- Não aplicável: nenhum trecho foi gerado por IA nesta feature.

### 2) Smart Suggestions

Objetivo
- Sugerir hábitos iniciais adequados ao perfil do usuário para facilitar engajamento.

IA usada?
- Atualmente NÃO (stub local). O design prevê substituição por IA. Se for usada IA,
  inserir aqui os prompts e explicações.

Prompt(s) exemplo (caso venha a usar IA)
- Prompt base (exemplo):
  "Dado um usuário com idade X, atividades Y e objetivos Z, gere 5 sugestões de
  hábitos curtos, explicando por que cada um é útil e fornecendo um nível de esforço
  de 1-5." 

Comentários sobre o prompt
- Separe contexto (perfil) do pedido principal (gerar sugestões) e peça formato JSON
  estruturado para facilitar parsing.

Exemplos de entrada e saída (3 casos):
- Caso A — Perfil iniciante
  - Entrada: {"idade":25, "atividade": "sedentário", "objetivo":"energia"}
  - Saída (stub): ["Caminhar 10 minutos", "Beber 2 copos de água pela manhã", ...]
- Caso B — Perfil ocupado
  - Entrada: {"idade":40, "atividade":"ocupado", "objetivo":"stress"}
  - Saída (stub): ["Respiração 3 minutos", "Pausa alongamento 5 minutos", ...]
- Caso C — Perfil ativo
  - Entrada: {"idade":30, "atividade":"ativo", "objetivo":"melhorar sono"}
  - Saída (stub): ["Evitar telas 30 min antes de dormir", "Rotina relax 10 min", ...]

Como testar localmente (passo a passo)
1. Rode o app com `flutter run`.
2. Abra a tela de sugestões. O widget consome `SmartSuggestionService`.
3. Para testar variações, ajuste o retorno do stub em
   `lib/features/smart_suggestions/smart_suggestion_service.dart` (simular diferentes
   perfis e respostas). Se integrar IA, configurar variável de ambiente / URL do endpoint
   e chave no local config.

Limitações e riscos
- Sugestões geradas por IA podem conter vieses; é necessário revisar e filtrar
  conteúdo sensível (privacidade e segurança). Não enviar dados pessoais sensíveis a
  um serviço de terceiros sem consentimento explícito.

Código gerado pela IA (se aplicável)
- Não aplicável no estado atual. Caso a equipe utilize IA para gerar código, inclua
  aqui os trechos relevantes e comentários linha-a-linha.

Logs de experimentos (opcional)
- [Opcional] Registre iterações de prompt/resposta, parâmetros do modelo (temperatura,
  max_tokens), e decisões tomadas entre versões do prompt.

## Roteiro de apresentação oral

- 1) Breve sumário do que foi implementado (1–2 minutos): goals e features.
- 2) Arquitetura e fluxo de dados (1–2 minutos): mostre o diagrama ASCII e explique
  onde a IA pode entrar.
- 3) Demonstração ao vivo (3–5 minutos): abrir o app, mostrar `Progress Overview` e
  `Smart Suggestions` (mudar o stub para mostrar variações).
- 4) Como a IA ajudou (se usada): explique prompts, decisões e como avaliações de
  qualidade/segurança foram feitas.
- 5) Limitações e próximos passos (1–2 minutos): persistência, métricas e testes A/B.

Pontos sobre segurança/ética
- Nunca envie informações sensíveis a serviços externos sem consentimento.
- Realize filtragem e validação do output da IA antes de apresentá-lo ao usuário.

## Política de branches e commits (obrigatória)

Fluxo sugerido adotado durante o desenvolvimento (recomendado e documentado aqui):

- Para cada nova feature, criar uma branch dedicada a partir de `main`:
  - Ex.: `feature/progress-overview` ou `feature/smart-suggestions`.
- Fazer commits pequenos e focados com mensagens claras (imperativo):
  - Ex.: "feat(progress): add ProgressOverview widget"
  - Ex.: "fix(suggestions): correct null handling in SmartSuggestionService"
- Registrar um commit para cada objetivo concluído (ex.: implementação inicial,
  testes unitários, correção de bugs). Evitar commits gigantescos que misturam várias
  responsabilidades.
- Abrir Pull Request para `main` quando a feature estiver pronta; usar revisão por
  pares e testes automatizados (quando possível) antes do merge.

Exemplo de prática de commits
- `git checkout -b feature/smart-suggestions`
- Trabalhar e commitar incrementalmente:
  - `git add .` / `git commit -m "feat(suggestions): add initial stub service"`
  - `git commit -m "test(suggestions): add unit tests for suggestion logic"`
- Após revisão e aprovação, fazer merge via PR.

Observação final
- Se a equipe decidir integrar IA no futuro, registre todos os prompts e as iterações
  em `prompts/` (por exemplo `prompts/smart_suggestions_v1.md`) para auditoria e
  reproducibilidade.

---

Se quiser, posso também:
- adicionar exemplos reais de prompts usados (caso já tenha usado IA) e gravar os
  logs de experimento em `prompts/`;
- criar um pequeno script de testes para simular entradas e verificar as saídas das
  features (unit tests).

