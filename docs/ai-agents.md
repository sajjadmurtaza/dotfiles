# AI agent skills

The repository keeps one portable skill source in `agents/skills/`. The same `SKILL.md` workflow is consumed by Codex, Claude Code, and Cursor; there are no divergent copies to maintain.

## Install

### Global — recommended for personal use

From the dotfiles repository root, install once and use the skills from every repository:

```sh
npx skills add ./agents/skills \
  -g \
  --copy \
  -a codex -a claude-code -a cursor \
  --skill dev ruby-dev ruby-on-rails-dev code-review pull-request \
  -y
```

The global location is `~/.agents/skills/<skill-name>/`. Open a new task or agent session after installing so its skill catalog refreshes. Use `npx skills list -g` to inspect the global installation.

> [!IMPORTANT]
> A global installation is available from every repository. Do not repeat the project-local installation unless the repository should carry and maintain its own skill copies.

### Update a global installation

Update all globally installed skills from their recorded source, then confirm what is installed:

```sh
npx skills update -g -y
npx skills list -g
```

Update selected skills only:

```sh
npx skills update code-review dev ruby-dev ruby-on-rails-dev pull-request -g -y
```

> [!TIP]
> Restart the agent or open a new task/session after updating. Maintainers testing unpushed edits should rerun the global `npx skills add ./agents/skills ... --copy` command from the dotfiles repository root instead; `skills update` follows the recorded published source.

### Project-local — optional

Use this only when a team intentionally wants the skills stored with one repository. Run it from that repository, set the source to the published dotfiles repository, and omit `-g`:

```sh
DOTFILES_SKILLS_SOURCE="https://github.com/your-account/dotfiles/tree/main/agents/skills"
npx skills add "$DOTFILES_SKILLS_SOURCE" \
  --copy \
  -a codex -a claude-code -a cursor \
  --skill dev ruby-dev ruby-on-rails-dev code-review pull-request \
  -y
```

This creates repository-level agent files. Review them like code and commit them only with team agreement. You do not need to repeat this in every repository when the global installation is present.

> [!WARNING]
> Project-local skills become part of that repository's maintenance surface. Commit them only when the team has agreed to review and update them.

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

Codex officially scans user skills in `~/.agents/skills`. See [OpenAI's skill documentation](https://developers.openai.com/codex/skills). The complete catalog and authoring rules live in [`../agents/skills/README.md`](../agents/skills/README.md).
