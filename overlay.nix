self: super: {
  kakounePlugins = super.kakounePlugins // {
    kak-jira = super.callPackage ./derivation.nix {
      fetchFromGitHub = _: ./.;
    };
  };
}
