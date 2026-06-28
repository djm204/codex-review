# codex-review

A [Claude Code](https://claude.com/claude-code) plugin providing a **reusable skill** for
driving the GitHub Codex bot (`chatgpt-codex-connector`) through a complete
review → address → resolve loop on a pull request until it reports no major issues.

## Why

The Codex review loop has non-obvious mechanics that are easy to get wrong:
- Codex signals its outcome across **three** GitHub channels (issue comments, PR reviews,
  inline comments).
- A **clean pass is a top-level issue comment** ("Didn't find any major issues"), not
  silence — a poller watching only inline comments hangs indefinitely.
- Availability **detection** needs an App-authorized token to list installed apps, so a
  plain user token can't prove a connector is present on a fresh repo.

This plugin captures all of that once, so any project can `@codex review` reliably.

## Install

```
/plugin marketplace add djm204/codex-review
/plugin install codex-review
```

Requires authenticated [`gh`](https://cli.github.com/) and `jq`, plus the GitHub Codex
connector installed on the target repo.

## Use

The `codex-review-loop` skill activates when a PR needs a Codex review driven to
resolution. It uses the bundled `codex-review-loop.sh` for the mechanical steps
(detect / trigger / poll / classify) and leaves judgement — is a finding real, how to fix
it — to the agent.

```bash
# the script is usable directly too:
skills/codex-review-loop/codex-review-loop.sh --help
```

## Develop

```bash
bash skills/codex-review-loop/tests/run.sh   # 14 dependency-free tests
```

## License

MIT
