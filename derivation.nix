{ stdenv, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "kak-jira";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "eraserhd";
    repo = pname;
    rev = "v${version}";
    sha256 = "";
  };

  installPhase = ''
    mkdir -p $out/share/kak/autoload/plugins/
    cp rc/jira.kak $out/share/kak/autoload/plugins/
  '';

  meta = with lib; {
    description = "JIRA syntax files for Kakoune";
    homepage = "https://github.com/eraserhd/kak-jira";
    license = licenses.publicDomain;
    platforms = platforms.all;
    maintainers = [ maintainers.eraserhd ];
  };
}
