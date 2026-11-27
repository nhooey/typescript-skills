{
  description = "typescript-skills: Agent skills for writing TypeScript, as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # Declared explicitly even though `agent-skill-flake` already pulls in
    # `treefmt-nix` transitively: this flake owns its formatter toolchain
    # rather than borrowing a dependency's. The consumer below `follows` this
    # input so the whole tree resolves to one version.
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # `agent-skill-flake` is the builder library, not a skill — it turns skill
    # directories into installable flakes and aggregates them, and exports the
    # `flakeModules.devshellSkills` flake-parts module that wires the dev shell
    # below (motd + install-skills startup + the ci/dev/maintenance command
    # trio + the reap-skills/update-skills-devshell pair). That module bundles
    # numtide/devshell, so this flake needs no `devshell` input of its own. It
    # carries zero skill inputs, so keeping it here does not drag the skill mesh
    # into the root lock; the dev-shell skill sources live only in the
    # `skills-devshell/` sub-flake's lock and are invoked at RUNTIME.
    agent-skill-flake = {
      url = "github:nhooey/agent-skill-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };

  outputs =
    {
      nixpkgs,
      flake-parts,
      agent-skill-flake,
      ...
    }@inputs:
    let
      # Each skill is a directory under ./skills. Until the first one lands
      # there is no ./skills to build, install or test, so the outputs below
      # that need it are empty.
      hasSkills = builtins.pathExists ./skills;

      # The skills this repo outputs: every skill under ./skills built into
      # per-skill packages plus the base install/preview apps. The dev-shell
      # skill set is NOT an output here — it lives in the `skills-devshell/`
      # sub-flake and is invoked at runtime by the dev shell below.
      base = agent-skill-flake.lib.mkAllSkillsFlake {
        inherit nixpkgs;
        source = import ./source.nix;
        skillsDir = ./skills;
        packagePrefix = "agent-skill-";
        # Ship the reference pages a SKILL.md links beside it (examples.md,
        # commands.md, ...); by default only SKILL.md, references/ and
        # scripts/ are installed. Lower-case names only, so a skill's
        # README.md stays in the repo for people instead of being installed.
        extraFiles = [ "[a-z]*.md" ];
        # Name the aggregate by owner+topic (agent-skills-nhooey-typescript-all)
        # rather than the owner-wide `agent-skills-nhooey-all`. The owner-wide
        # key would collide across all repos this owner publishes under
        # skillspkgs / nur-packages' last-write-wins `//` merge; the
        # owner+topic name is resolvable and unique, mirroring python-skills's
        # `agent-skills-nhooey-python-all`. The aggregate carries the
        # home-manager `isFlakeSkillsEnv` passthru itself, so `default` is
        # directly installable — no hand-rolled pack.
        name = "agent-skills-nhooey-typescript-all";
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        # Bundles numtide/devshell + the whole dev-shell skills convention
        # (motd, install-skills startup, the ci/dev/maintenance command trio,
        # and the reap-skills/update-skills-devshell pair). Configured via the
        # `agent-skill-flake.devshellSkills` options block below. The dev-shell
        # skill set is defined in the runtime `skills-devshell/` sub-flake and
        # invoked at RUNTIME, never as a root input, so this repo keeps zero
        # skill inputs in its own lock.
        inputs.agent-skill-flake.flakeModules.devshellSkills
        inputs.treefmt-nix.flakeModule
      ];

      # Keep typescript-skills' custom banner; the module's generated motd is
      # overridden by passing `motd` here.
      agent-skill-flake.devshellSkills = {
        name = "typescript-skills";
        motd = ''
          {bold}{14}🚀 Entering typescript-skills dev shell{reset}
          Run {bold}menu{reset} to list available commands.
        '';
      };
      perSystem =
        { system, pkgs, ... }:
        {
          packages = if hasSkills then base.packages.${system} else { };

          apps = if hasSkills then base.apps.${system} else { };

          # Build every skill package and the aggregate under `nix flake
          # check`, so a skill that fails to build fails the check rather
          # than only `nix build`. `default` is the aggregate again. Then run
          # each skill's "Your preferences" command line against a skill
          # folder symlinked into a fake Nix store.
          checks = nixpkgs.lib.optionalAttrs hasSkills (
            removeAttrs base.packages.${system} [ "default" ]
            // {
              preferences-section-test = pkgs.runCommand "preferences-section-test" { } ''
                ${pkgs.bash}/bin/bash ${./checks/preferences-section-test.sh} ${./skills}
                touch $out
              '';
            }
          );

          # `nix fmt` runs nixfmt over `.nix` and prettier over `.md` / `.yaml`;
          # the module also surfaces a `checks.${system}.treefmt` so `nix flake
          # check` fails on any unformatted file. prettier's includes are pinned
          # to markdown and YAML so it leaves any JSON alone — add formatters
          # here as other tracked file types arrive.
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.prettier.enable = true;
            settings.formatter.prettier.includes = [
              "*.md"
              "*.yaml"
              "*.yml"
            ];
          };

          # The devshellSkills module (imported above) supplies this devShell's
          # name, motd, the install-skills startup that reconciles the runtime
          # `skills-devshell/` sub-flake at project scope, the ci/dev/maintenance
          # command trio (check / fmt / update-flake), and the skills commands
          # (reap-skills / update-skills-devshell). This repo adds no dev-shell
          # packages or commands of its own, so there is no `devshells.default`
          # block here.
        };
    };
}
