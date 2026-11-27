{
  description = "typescript-skills dev-shell skill set — an isolated sub-flake invoked at RUNTIME by the root devShell, never a root input. The skill sources live only in THIS flake's lock, so the root typescript-skills stays a leaf with zero skill inputs and transitive consumers never drag the skill mesh in.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    # The builder lib. agent-skill-flake carries zero skill inputs, so it does
    # not drag the skill mesh into this sub-flake's lock — only the skill
    # combination below does.
    agent-skill-flake = {
      url = "github:nhooey/agent-skill-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # skillspkgs' per-family combinations, surfaced through its own subdir
    # flake (`mkCombination` keeps a combination re-composable). It follows
    # `nixpkgs` but not `agent-skill-flake`: forcing the combination's
    # transitive sources onto a single pinned builder surfaces an ownerless
    # aggregate-key the strict namespace check rejects, so the combination
    # keeps its own (compatible) builder. `mkDevshellSkillsFlake` still runs
    # from this flake's `agent-skill-flake.lib`, so the combiner is the pinned
    # rev above.
    skillspkgs-combinations = {
      url = "github:nhooey/skillspkgs?dir=sources/combinations";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      agent-skill-flake,
      ...
    }@inputs:
    agent-skill-flake.lib.mkDevshellSkillsFlake {
      inherit nixpkgs;
      systems = import inputs.systems;
      name = "typescript-skills-devshell";
      sources = [
        # The skill-collections family's combination, shared by every skill
        # collection: the base skills plus skill authoring. No additions.
        { source = inputs.skillspkgs-combinations.combinations.skill-collections; }
      ];
    };
}
