# Skill: `codex-review-loop`

Human-facing reference. The authoritative, agent-facing spec is
[`skills/codex-review-loop/SKILL.md`](../../skills/codex-review-loop/SKILL.md); this page
explains what the skill is, when it fires, and what to expect.

## What it does

Drives the GitHub Codex bot (`chatgpt-codex-connector`) through a full
**review → address → resolve** cycle on a pull request until Codex reports no major issues.
The mechanical steps (detecting availability, triggering, polling, classifying the outcome)
are handled by the bundled `codex-review-loop.sh`; the judgement — *is a finding real, and
how do I fix it* — stays with the calling agent.

## When it activates

Use it when:
- a PR was just opened or updated and needs review before merge,
- you're told to "run the codex loop", comment `@codex review`, or address Codex feedback,
- a pre-merge / task-end gate requires a clean Codex pass.

Not for human review threads or CI checks — specifically the Codex bot.

## The loop at a glance

1. **Detect** whether the connector is available (`true` / `false` / `"unknown"`).
2. **Trigger** a review (`@codex review`) and record the server timestamp.
3. **Poll** all three channels for bot activity newer than that timestamp.
4. **Classify** the result: `clean` (terminal), `findings`, or `working` (keep polling).
5. **Address** each finding — decide if it's real, fix + reply + resolve, or reply why it
   isn't and resolve. Re-trigger and repeat until `clean`.

## Script actions

`codex-review-loop.sh` (referenced via `${CLAUDE_PLUGIN_ROOT}/skills/codex-review-loop/`):

| Action | Purpose |
|--------|---------|
| `detect --repo R` | Is the connector available? Tri-state JSON. |
| `trigger --repo R --pr N` | Post `@codex review`; prints the server `created_at` boundary. |
| `poll --repo R --pr N --since TS` | Classify bot activity since `TS` → `{status, findings}`. |
| `classify --input FILE` | Pure classifier (no network) — for tests. |
| `detect-classify --input FILE` | Pure app-list availability classifier — for tests. |

Run `codex-review-loop.sh --help` for the full interface.

## Gotchas worth knowing

- Codex signals across **three** channels — poll issue comments, PR reviews, and inline
  comments. A clean pass is a **top-level issue comment** ("Didn't find any major issues"),
  not silence and not only inline comments.
- The "💡 Codex Review" wrapper review is **not** an actionable finding — it's filtered out.
- `detect` is tri-state; a fresh repo with a non-App token returns `"unknown"`, which means
  "trigger and decide empirically" — never a false negative.

See SKILL.md for the complete gotcha list and rationale.

## Testing

```bash
bash skills/codex-review-loop/tests/run.sh
```

Covers the pure `classify` and `detect-classify` paths (no network) with fixtures.
