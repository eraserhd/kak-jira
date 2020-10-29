{ stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "kak-jira";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "eraserhd";
    repo = pname;
    rev = "v${version}";
    sha256 = "";
  };

  meta = with stdenv.lib; {
    description = "JIRA syntax files for Kakoune";
    homepage = "https://github.com/eraserhd/kak-jira";
    license = licenses.publicDomain;
    platforms = platforms.all;
    maintainers = [ maintainers.eraserhd ];
  };
}