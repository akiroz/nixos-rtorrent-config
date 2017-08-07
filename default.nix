{ ... }: let
  mkRtorrentInstance = import ./rtorrent.nix;
in {
  imports = [
    (mkRtorrentInstance 1)
    (mkRtorrentInstance 2)
    (mkRtorrentInstance 3)
    (mkRtorrentInstance 4)
    (mkRtorrentInstance 5)
    (mkRtorrentInstance 6)
    (mkRtorrentInstance 7)
    (mkRtorrentInstance 8)
    (mkRtorrentInstance 9)
    (mkRtorrentInstance 10)
  ];
}

