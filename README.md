# 📱 TrackHabits — Hábitos Simples

> Aplicativo Flutter para criar e acompanhar hábitos diários de forma simples, com fluxo inicial guiado e foco em privacidade (LGPD).

---

## 🧭 Visão Geral

O **TrackHabits** é um app voltado a estudantes que buscam desenvolver **pequenos hábitos diários** com uma interface limpa e intuitiva.  
Na **primeira execução**, o usuário é guiado por um onboarding curto, lê e aceita as políticas de privacidade, cria seu primeiro hábito (ex.: *beber água*) e ativa um lembrete.

### 🎯 Objetivo
Reduzir o atrito da primeira configuração e incentivar consistência por meio de hábitos simples.

### 🧩 Principais Funcionalidades
- Onboarding rápido (2 telas + consentimento)
- Visualização de políticas em Markdown
- Consentimento explícito e versionado (LGPD)
- Criação e acompanhamento de hábitos
- Lembretes personalizados
- Revogação de consentimento com opção de desfazer

---

## 🧍 Persona

**Estudante universitário** com rotina irregular, que busca pequenas vitórias diárias e quer melhorar sua organização pessoal.

---

## 🎨 Identidade Visual

| Elemento | Valor |
|-----------|--------|
| **Primária** | `#059669` (Emerald) |
| **Secundária** | `#4F46E5` (Indigo) |
| **Superfície** | `#FFFFFF` |
| **Texto** | `#0F172A` |
| **Estilo** | Flat minimalista, Material 3, alto contraste (WCAG AA) |
| **Ícone do app** | Calendário com check — paleta Emerald/Indigo/Surface |

**Prompt do ícone**  
> “Flat vector circular badge, transparent background, center: calendar page with a checkmark; minimal stroke, slight shadow; palette Emerald #059669, Indigo #4F46E5, Surface #FFFFFF; high contrast; no text; 1024x1024.”

---

## 🧭 Fluxo de Primeira Execução

1. **Splash** → verifica flags de aceite e onboarding.  
2. **Onboarding (2 telas + consentimento)**  
   - Tela 1: Boas-vindas e benefícios  
   - Tela 2: Como funciona  
   - Tela 3: Consentimento (sem pular)  
3. **Leitura das Políticas** → viewer Markdown com barra de progresso.  
4. **Aceite** → botão habilitado apenas após leitura completa.  
5. **Criação do 1º Hábito** → “Beber água”, lembrete padrão 09:00.  
6. **Home** → exibe progresso e permite marcar como concluído.  
7. **Configurações → Revogar Consentimento** → diálogo + Snackbar “Desfazer”.

---

## ⚙️ Requisitos Funcionais

| ID | Descrição |
|----|------------|
| RF-1 | DotsIndicator sincronizado e oculto na última tela do onboarding. |
| RF-2 | Botão **Pular** vai direto ao consentimento. |
| RF-3 | Viewer Markdown com barra de progresso. |
| RF-4 | Consentimento habilitado apenas após leitura completa. |
| RF-5 | Splash decide rota com base em flags (`policies_version_accepted`, `onboarding_completed`). |
| RF-6 | Criação automática do hábito “Beber água”. |
| RF-7 | Revogação com confirmação + Snackbar “Desfazer”. |
| RF-8 | Persistência do aceite com versão e timestamp. |
| RF-9 | Ícone gerado via `flutter_launcher_icons`. |

---

## 🧩 Requisitos Não Funcionais

- **Acessibilidade (A11Y)**: targets ≥ 48dp, suporte a text scaling ≥ 1.3.  
- **Privacidade**: consentimento explícito e revogável (LGPD).  
- **Arquitetura**: `UI → Service → Storage` (sem acesso direto ao `SharedPreferences`).  
- **Performance**: animações ~300ms, carregamento eficiente de Markdown.  
- **Testabilidade**: `PrefsService` mockável, rotas independentes.

---

## 💾 Estrutura de Dados

| Chave | Tipo | Descrição |
|--------|------|-----------|
| `privacy_read_v1` | bool | Política de privacidade lida |
| `terms_read_v1` | bool | Termos lidos |
| `policies_version_accepted` | string | Versão do aceite |
| `accepted_at` | string | Data/hora ISO8601 |
| `onboarding_completed` | bool | Onboarding concluído |
| `first_habit_created` | bool | Indica criação do primeiro hábito |
| `habit_{id}` | objeto | Dados do hábito (título, meta, lembrete) |

**Serviço sugerido:** `PrefsService`  
Métodos principais:  
`getBool`, `setBool`, `getString`, `setString`, `saveHabit`, `getHabit`, `deleteHabit`, `isFullyAccepted`, `migratePolicyVersion`.

---

## 🗺️ Rotas Principais

| Rota | Tela |
|------|------|
| `/` | Splash |
| `/onboarding` | PageView (2–3 telas) |
| `/policy-viewer` | Viewer Markdown |
| `/create-habit` | Criação de hábito |
| `/home` | Tela inicial |
| `/settings/privacy` | Revogação e visualização de políticas |

---

## ✅ Critérios de Aceite

- Dots sincronizados e ocultos na última tela.  
- Botões de navegação com comportamento contextual.  
- Leitura completa exigida antes do aceite.  
- Splash direciona corretamente.  
- Revogação funcional com Snackbar “Desfazer”.  
- Nenhum acesso direto ao `SharedPreferences`.  
- Ícone gerado corretamente e aplicado.

---

## 🧪 Testes Manuais

1. Fluxo completo de onboarding e aceite.  
2. Verificar que o botão “Concordo” só habilita após leitura total.  
3. Testar persistência (`prefs`) e redirecionamento após reabrir o app.  
4. Testar revogação com e sem “Desfazer”.  
5. Conferir contraste e acessibilidade.

---

## ⚠️ Riscos e Decisões

- **Risco:** esquecer versionamento do aceite → mitigado via `policies_version_accepted`.  
- **Decisão:** políticas mantidas como assets offline.  
- **Risco:** acoplamento UI–storage → mitigado por `PrefsService` injetável.

---

## 🚀 Entregáveis

1. Implementação completa do fluxo inicial (Splash, Onboarding, Consentimento, Criação de hábito).  
2. Ícone gerado com `flutter_launcher_icons`.  
3. Evidências (prints) das telas principais.  
4. Código seguindo arquitetura `UI → Service → Storage`.

---

## 🧱 Tecnologias

- **Flutter** (Material 3)
- `dots_indicator`
- `flutter_launcher_icons`
- `provider` ou `get_it` para injeção de dependência
- `shared_preferences` via camada de serviço

---

## 📈 Backlog Futuro

- Histórico de aceites.  
- Hash de políticas para invalidação automática.  
- Lembretes inteligentes (snooze).  
- Gamificação (streaks, medalhas).

---

## 👤 Autor

**João Vitor Herzer**  
Disciplina: *Aplicações para Dispositivos Móveis*  
Instituição: UTFPR  
Versão: **v1.5.12 — Dezembro/2025**

Professor: Everton Coimbra De Araujo
---
