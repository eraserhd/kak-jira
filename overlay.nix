self: super: {
  kak-jira = super.callPackage ./derivation.nix {
    fetchFromGitHub = _: ./.;
  };
}
