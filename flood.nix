{ stdenv
, fetchFromGitHub
, nodePackages
, writeText
, nodejs
, ... }:

let
  configFile = writeText "flood-config.js" ''
    const CONFIG = {
      baseURI: '/',
      dbCleanInterval: 1000 * 60 * 60,
      dbPath: './server/db/',
      floodServerHost: '0.0.0.0',
      floodServerPort: process.env.FLOOD_SERVER_PORT,
      maxHistoryStates: 30,
      pollInterval: 1000 * 5,
      secret: 'flood',
      scgi: {
        socket: true,
        socketPath: process.env.RTORRENT_SCGI_SOCKET,
      },
      ssl: false,
      torrentClientPollInterval: 1000 * 2,
    };
    module.exports = CONFIG;
  '';
in stdenv.mkDerivation rec {
  name = "flood-${version}";
  version = "e3c2f8e";
  src = fetchFromGitHub {
    owner = "jfurrow";
    repo = "flood";
    rev = version;
    sha256 = "1dfw2a3y7rzr7ir30flp9k624d3paxb2287mpdb04mghrx5ba3r9";
  };
  buildInputs = [ nodePackages.npm nodejs ];
  installPhase = ''
    export HOME="."
    mkdir $out
    cp -r ./* $out/
    cd $out
    npm install --production
    cp ${configFile} config.js
  '';
}

