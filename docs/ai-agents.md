# AI agent skills

The repository keeps one portable skill source in `agents/skills/`. The same `SKILL.md` workflow is consumed by Codex, Claude Code, and Cursor; there are no divergent copies to maintain.

## Install

The dotfiles installer links the canonical tree into `~/.agents/skills/`:

```sh
./install --profile rails
```

For a project-local or cross-agent installation without the rest of the dotfiles, use the Skills CLI:

```sh
npx skills add sajjadmurtaza/dotfiles/agents/skills \
  -a codex -a claude-code -a cursor \
  --skill dev ruby-dev ruby-on-rails-dev code-review \
  -y
```

Omit `-g` for project-local installation. Add `-g` when you want the skills available in every project.

## Invoke

| Agent | Explicit use | Discover |
| --- | --- | --- |
| Codex | Mention `$dev` or `$ruby-on-rails-dev` | `/skills` or type `$` |
| Claude Code | Run `/dev` or `/ruby-on-rails-dev` | `/skills` |
| Cursor | Select `/dev` or `/ruby-on-rails-dev` | type `/` in Agent chat |

Agents can also select a skill automatically from its description. Explicit invocation is useful when the workflow must be predictable.

## Rails example

```text
Use $dev, $ruby-dev, and $ruby-on-rails-dev to add account suspension.
Follow repository conventions, keep the design KISS, test authorization and
tenant boundaries, run the native CI gate, then use $code-review.
```

The Rails overlay loads only the focused reference needed for models, controllers, Hotwire, jobs, data, tests, security, performance, or deployment. The root skill stays concise so routine work does not consume the full reference set.

## Safe agent configuration

- Skills contain instructions and optional local scripts; read their diffs like code.
- No tracked Claude configuration enables `bypassPermissions` or broad command allowlists.
- Agent-specific credentials and MCP connections stay in each agent's local settings, not this public repository.
- Project rules remain authoritative. A skill should adapt to the repository rather than replace its architecture.

Codex officially scans user skills in `~/.agents/skills` and follows symlink targets. See [OpenAI's skill documentation](https://developers.openai.com/codex/skills). The complete catalog and authoring rules live in [`../agents/skills/README.md`](../agents/skills/README.md).
