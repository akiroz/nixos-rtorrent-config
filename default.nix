{ ... }: let
  globalEnable = false;
  mkRtorrentInstance = import ./rtorrent.nix;
in {
  users.extraUsers.rtorrent = {
    isNormalUser = true;
    extraGroups = [ "storage" ];
  };
  imports = [
    (mkRtorrentInstance { id = 1;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 2;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 3;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 4;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 5;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 6;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 7;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 8;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 9;   enable = globalEnable && true; })
    (mkRtorrentInstance { id = 10;  enable = globalEnable && true; })
  ];
}
