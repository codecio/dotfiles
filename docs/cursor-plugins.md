# Cursor Plugins & Skills

What I run in Cursor: **marketplace plugins** (installed via Cursor, cached under `~/.cursor/plugins/`) and **personal skills** (chezmoi-managed under `home/dot_cursor/skills/`). Plugins are managed by Cursor and synced to my account, so they are re-installed per machine from the UI — they are **not** carried by this repo. This page is the inventory + runbook.

## Installed inventory

<details>
<summary>Marketplace plugins currently installed</summary>

| Plugin | Version | Author | What it gives me |
|--------|---------|--------|------------------|
| `pstack` | 0.11.7 | Lauren Tan | Rigorous, parallelizable agent workflows via `/poteto-mode` |
| `cursor-team-kit` | 1.2.0 | Cursor | CI, code review, shipping, verification, cleanup workflows |
| `datadog` | 0.7.14 | Datadog | Datadog MCP — query logs, metrics, traces, dashboards in chat (preview) |
| `aws-core` | 1.1.0 | AWS | IaC (CDK/CloudFormation) + core services, observability, messaging, SDKs |
| `aws-serverless` | 1.1.1 | AWS | Design/build/deploy/debug serverless (Lambda, SAM, API Gateway, Step Functions) |
| `deploy-on-aws` | 1.2.0 | AWS | Deploy to AWS with architecture recs, cost estimates, draw.io diagrams |

Source of truth for enabled/disabled state is **Customize → Plugins** in Cursor, not the filesystem.

</details>

<details>
<summary>Personal skills (chezmoi-managed, in this repo)</summary>

These live under `home/dot_cursor/skills/` and apply to `~/.cursor/skills/` on `chezmoi apply` — see [chezmoi.md](chezmoi.md).

| Skill | Invocation | What it does |
|-------|-----------|--------------|
| `grill-me` | type `@grill-me` | Relentless one-question-at-a-time interview to sharpen a plan/decision |
| `research` | auto or by name | Background agent investigates against primary sources, writes cited findings |
| `handoff` | type `@handoff` | Compact the conversation into a handoff doc for a fresh agent |
| `writing-great-skills` | type `@writing-great-skills` | Reference for authoring predictable skills (+ `GLOSSARY.md`) |
| `teach` | type `@teach` | Stateful multi-session teaching workspace |

Origin: derived from [mattpocock/skills](https://github.com/mattpocock/skills).

</details>

## Setup runbook

<details>
<summary>Install plugins on a new machine (Customize UI — the reliable path)</summary>

Plugins install through Cursor's UI, not a chat command. Typing `/add-plugin <name>` in agent chat is **not** a registered command — it gets sent as a plain message and does nothing.

1. `Cmd+I` to open the Agents panel
2. Click **Customize** in the left sidebar → **Plugins** tab
3. Click **Browse Marketplace**, search the plugin name, click **Install**
4. Choose scope **User** (syncs to account / all machines) rather than **Workspace**
5. Confirm it appears as installed/enabled under **Customize → Plugins**

Alternative: type `/` in chat and pick **`/plugin`** from the autocomplete menu (note: `/plugin`, not `/add-plugin`), then install from the Marketplace tab.

If plugins don't appear in the marketplace:

- **Cursor Settings → Rules, Skills, Subagents → "Include third-party Plugins, Skills, and other configs"** must be ON
- Run **Developer: Reload Window** (`Cmd+Shift+P`)
- Requires a recent Cursor (marketplace Customize UI shipped in 3.9 / June 2026)

</details>

<details>
<summary>Post-install configuration</summary>

- **pstack models:** run `/setup-pstack` to pick which model each role uses. Writes `~/.cursor/rules/pstack-models.mdc` (`alwaysApply: true`); skills fall back to inline defaults for absent lines. Machine/model-specific — not tracked in this repo.
- **Datadog:** on install, set the `DD_MCP_DOMAIN` variable to your org's MCP domain (e.g. `mcp.datadoghq.com`, `mcp.us5.datadoghq.com`) per the [Datadog site guide](https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site). Requires Datadog auth.
- **Personal skills** (chezmoi): `chezmoi apply` drops them into `~/.cursor/skills/`. Reload the Cursor window to register new skills.

</details>

## pstack

<details>
<summary>What it is — rigorous, parallelizable agent workflows</summary>

By Lauren Tan ([@poteto](https://x.com/poteto)), a Cursor engineer / React core team member. Philosophy: "if you want to go fast, go deep first." It aims to write *less* but higher-quality code, with verification-driven workflows you can run many of in parallel with confidence.

- Ships: ~13 workflow skills, ~20 first-principles skills, and a `poteto-agent` subagent.
- Marketplace: [cursor.com/marketplace/cursor/pstack](https://cursor.com/marketplace/cursor/pstack)
- Mirror/source: [backnotprop/pstack](https://github.com/backnotprop/pstack)
- License: MIT

</details>

<details>
<summary>/poteto-mode — the router and its 14 playbooks</summary>

The main entry point. Start any non-trivial task with `/poteto-mode <task>`. It opens a todo list (first item: read its inline principles index), matches the task to a playbook, copies those steps in verbatim, and routes to supporting skills as steps fire. Pairs well with Cursor's `/loop` for long autonomous runs.

| Playbook | For |
|----------|-----|
| investigation | read-only question — how does X work, why was Y built this way |
| bug fix | reproduce a defect, root-cause it, fix with runtime evidence |
| perf | trace a measured slowness and improve against a baseline |
| runtime forensics | diagnose a live symptom (leak, idle-cpu spin, glitch) from instrumentation |
| trace forensics | diagnose a captured artifact (cpuprofile, trace, spindump, heap snapshot) |
| feature | new/changed behavior built from a named data shape |
| refactoring | behavior-preserving change to structure or shape |
| prototype | throwaway sketch to make a design decision cheaply |
| visual parity | pixel-exact UI equivalence between two implementations |
| authoring a skill | writing or editing a SKILL.md |
| eval | test how a skill/prompt change affects agent behavior, blinded |
| autonomous run | drive a long task to completion without stopping |
| session pickup | resume/take over a prior agent's in-flight work |
| multi-phase plan | work spanning phases or stacked PRs |

</details>

<details>
<summary>Directly-invocable skills</summary>

| Skill | Reach for it when |
|-------|-------------------|
| `/poteto-mode` | default entry point for any non-trivial task |
| `/how` | you want a walkthrough of how a subsystem works |
| `/why` | you want the rationale/history; queries available MCPs in parallel (source control, issues, docs, chat, observability, error tracking, analytics) |
| `/architect` | settle types and module shape before writing code across a boundary |
| `/arena` | N parallel attempts at the same task, then graft the best parts together |
| `/interrogate` | have four models try to break a diff/PR |
| `/blast-radius` | find what a change could break beyond the diff, proven by running code |
| `/automate-me` | draft your own `-mode` skill from how you've actually worked |
| `/reflect` | capture a finished long task's recipe as a skill edit |
| `/tdd` | cheap local test path exists — write the failing test first, then the fix |
| `/typescript-best-practices` | reading/editing TypeScript; grounds type-system discipline in syntax |
| `/figure-it-out` | no bundled playbook fits; designs a rigorous, auditable playbook |
| `/show-me-your-work` | want a reviewable decision trail logged to a committable TSV |
| `/unslop` | cleaning up writing — removes AI tells |
| `/create-verification-skill` | make a project-local skill that drives the real app to prove behavior |

</details>

<details>
<summary>The poteto-agent subagent + first-principles skills</summary>

- **`poteto-agent` subagent** — runs the style end-to-end. Spawn from a parent agent via `subagent_type: "poteto-agent"`; it reads `poteto-mode` in full (incl. principles index) before working. Substituting `generalPurpose` skips that read and drifts.
- **First-principles skills** (one principle each; `poteto-mode` indexes them inline):
  - core: laziness-protocol, foundational-thinking, redesign-from-first-principles, subtract-before-you-add, minimize-reader-load, outcome-oriented-execution, experience-first, exhaust-the-design-space, build-the-lever
  - architecture: boundary-discipline, type-system-discipline, make-operations-idempotent, migrate-callers-then-delete-legacy-apis, separate-before-serializing-shared-state, model-the-domain, sequence-verifiable-units
  - verification: prove-it-works, fix-root-causes
  - delegation: guard-the-context-window, never-block-on-the-human
  - meta: encode-lessons-in-structure

</details>

## cursor-team-kit

<details>
<summary>What it is — internal Cursor team workflows</summary>

Internal-style workflows Cursor developers use for CI, code review, shipping, local automation, and verification. Plug-and-play with no third-party service integrations required. Provides the skills pstack references but doesn't bundle (`/deslop`, `control-cli`, `control-ui`). Note: `/babysit` and `/create-skill` are Cursor built-ins, not part of this kit.

</details>

<details>
<summary>Skills, agents, rules</summary>

Skills:

| Skill | Description |
|-------|-------------|
| `loop-on-ci` | Watch CI runs and iterate on failures until checks pass |
| `review-and-ship` | Structured review, commit changes, open a PR |
| `pr-review-canvas` | Interactive HTML PR walkthrough with annotated, categorized diffs |
| `verify-this` | Prove/disprove claims with baseline vs treatment artifacts and a verdict |
| `control-cli` | Build/adapt a local harness to drive and profile interactive CLIs or TUIs |
| `control-ui` | Build/adapt a local browser/CDP harness for web or Electron UIs |
| `make-pr-easy-to-review` | Clean noisy PR history, improve descriptions, add reviewer guidance |
| `run-smoke-tests` | Run Playwright smoke tests and triage failures |
| `fix-ci` | Find failing CI jobs, inspect logs, apply focused fixes |
| `new-branch-and-pr` | Create a branch, complete work, open a PR |
| `get-pr-comments` | Fetch and summarize review comments on the active PR |
| `check-compiler-errors` | Run compile/type-check commands and report failures |
| `what-did-i-get-done` | Summarize authored commits over a period into a status update |
| `weekly-review` | Weekly recap of shipped work (bugfix/tech-debt/net-new) |
| `fix-merge-conflicts` | Resolve conflicts, validate build/tests, summarize decisions |
| `deslop` | Remove AI-generated code slop and clean up style |
| `workflow-from-chats` | Extract durable working preferences from chats into skills/rules/docs |
| `thermo-nuclear-code-quality-review` | Unusually strict maintainability review (code-judo, 1k-line rule, spaghetti, boundaries) |

Agents: `ci-watcher` (GitHub Actions pass/fail summaries), `thermo-nuclear-code-quality-review` (strict quality rubric against a diff).

Rules: `typescript-exhaustive-switch`, `no-inline-imports`.

</details>

## Datadog

<details>
<summary>Datadog MCP plugin (preview)</summary>

Query Datadog directly in chat through a preconfigured Datadog MCP server — logs, metrics, traces, dashboards, and more via natural conversation. Directly relevant to this `datadog_automation` work.

- Author: Datadog. Repo: [datadog-labs/cursor-plugin](https://github.com/datadog-labs/cursor-plugin)
- Config: set `DD_MCP_DOMAIN` to your org's domain (e.g. `mcp.datadoghq.com`, `mcp.us3/us5.datadoghq.com`, `mcp.datadoghq.eu`, `mcp.ap1/ap2.datadoghq.com`) — see the [site guide](https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site)
- Requires Datadog authentication

</details>

## AWS plugins

<details>
<summary>aws-core, aws-serverless, deploy-on-aws</summary>

Official AWS plugins ([aws/agent-toolkit-for-aws](https://github.com/aws/agent-toolkit-for-aws), [awslabs/agent-plugins](https://github.com/awslabs/agent-plugins)), Apache-2.0.

| Plugin | Scope |
|--------|-------|
| `aws-core` | Author IaC (CDK, CloudFormation), use core services (Lambda, API Gateway, Step Functions, ECS/Fargate, ECR, IAM, Bedrock, Amplify), plus observability (CloudWatch, X-Ray, CloudTrail, ADOT), messaging/streaming (SQS, SNS, EventBridge, Kinesis, MSK), SDKs (boto3, JS v3, Swift), and cost optimization. Includes an MCP server. |
| `aws-serverless` | Design, build, deploy, test, and debug serverless apps (Lambda, SAM, API Gateway, EventBridge, Step Functions) |
| `deploy-on-aws` | Deploy to AWS with architecture recommendations, cost estimates, IaC deployment, and validated draw.io architecture diagrams |

</details>
