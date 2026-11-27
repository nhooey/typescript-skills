# typescript-skills

Agent skills for writing TypeScript, packaged as a Nix flake.

Each skill is a self-contained directory `skills/<name>/` with a `SKILL.md`
that an agent loads on demand. Skills are built by
[`agent-skill-flake`](https://github.com/nhooey/agent-skill-flake).

## Install

```bash
# Preview what installing every skill would change, without writing anything
nix run github:nhooey/typescript-skills#preview

# Install all skills into the agent's skill directory
nix run github:nhooey/typescript-skills#install
```

Package outputs:

- `agent-skills-nhooey-typescript-all` — the aggregate of every skill (also `default`)

## Development

Run `nix develop` to enter the dev shell, then `menu` to list its commands:
`check` builds every skill, runs each skill's "Your preferences" line through
a symlinked skill folder and fails on any unformatted file, `fmt` formats the
tree, and `update-flake` updates the flake inputs.
