{ nixpkgs ? (import ./nixpkgs.nix), ... }:
let
  pkgs = import nixpkgs {
    config = {};
    overlays = [
      (import ./overlay.nix)
    ];
  };
in {
  test = pkgs.runCommandNoCC "kak-jira-test" {} ''
    mkdir -p $out
    : ${pkgs.kak-jira}
  '';
}