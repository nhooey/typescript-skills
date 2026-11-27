# typescript-skills

Agent skills for writing TypeScript, packaged as a Nix flake. Each skill is a directory `skills/<name>/` with a `SKILL.md` and its own sub-flake, built by agent-skill-flake; `source.nix` states the owner its package keys carry.

## Build and test

Enter the dev shell with `nix develop`; it installs skillspkgs' `skill-collections` combination, with no additions, into `.agents/skills/` from the `skills-devshell/` sub-flake, and `menu` lists its commands:

- `check`: builds every skill package and the aggregate, runs `checks/preferences-section-test.sh` on each skill's "Your preferences" line, and fails on any file `fmt` would change.
- `fmt`: formats every file, nixfmt over `.nix` and prettier over Markdown and YAML.
- `update-flake`: updates the flake inputs and rewrites `flake.lock`.
- `update-skills-devshell`: bumps the `skills-devshell/` sub-flake's lock, the dev shell's skill set.
- `reap-skills`: removes the skills the dev shell installed.
