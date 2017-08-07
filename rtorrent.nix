id: { pkgs, ... }: let
  flood = import ./flood.nix pkgs;
  bash      = "/run/current-system/sw/bin/bash";
  userID    = 40000 + id;
  peerPort  = 40000 + id;
  dhtPort   = 41000 + id;
  floodPort = 42000 + id;
  user = "rtorrent-${toString id}";
  rpcSocket = "/home/${user}/rtorrent.sock";
  session   = "/home/${user}/rtorrent.dtach";
  pidFile   = "/home/${user}/rtorrent.pid";
  rtorrentRC = pkgs.writeText "rtorrent.rc" ''
    directory.default.set                 = /mnt/storage/rtorrent/data
    session.path.set                      = ~
    network.scgi.open_local               = ${rpcSocket}
    throttle.global_down.max_rate.set_kb  = 9000
    throttle.global_up.max_rate.set_kb    = 500
    network.port_range.set                = ${toString peerPort}-${toString peerPort}
    network.port_random.set               = no
    protocol.encryption.set               = allow_incoming,try_outgoing,enable_retry
    trackers.use_udp.set                  = no
    protocol.pex.set                      = yes
    dht.mode.set                          = on
    dht.port.set                          = ${toString dhtPort}
    schedule2 = dht_add_node, 0, 0, "dht.add_node=router.bittorrent.com"
    execute.nothrow = ${bash}, -c, (cat, "echo -n > ${pidFile} ", (system.pid))
  '';
in {
  networking.firewall = {
    allowedTCPPorts = [ peerPort floodPort ];
    allowedUDPPorts = [ dhtPort ];
  };
  users.extraUsers."${user}" = {
    uid = userID;
    isNormalUser = true;
    extraGroups = [ "storage" ];
  };
  systemd.services = {
    "rtorrent-${toString id}" = let
      rm        = "/run/current-system/sw/bin/rm";
      kill      = "/run/current-system/sw/bin/kill";
      dtach     = "${pkgs.dtach}/bin/dtach";
      rtorrent  = "${pkgs.rtorrent}/bin/rtorrent";
    in {
      enable = true;
      serviceConfig = {
        User = "${user}";
        Group = "storage";
        Type = "forking";
        KillMode = "none";
        ExecStop = "${bash} -c '${kill} -s 15 `cat ${pidFile}` || true'";
        ExecStart = "${dtach} -n ${session} -E -z ${rtorrent} -n -o import=${rtorrentRC}";
        ExecStartPre = "${bash} -c 'if [ -f ${session} ]; then ${rm} ${session}; fi'";
        Restart = "on-failure";
      };
      environment = {
        TERM = "xterm";
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
    };
    "flood-${toString id}" = {
      enable = true;
      serviceConfig = {
        User = "${user}";
        WorkingDirectory = "/home/${user}";
        ExecStart = "${pkgs.nodejs}/bin/node ${flood}/server/bin/www";
        Restart = "on-failure";
      };
      environment = {
        NODE_ENV              = "production";
        FLOOD_SERVER_PORT     = toString floodPort;
        RTORRENT_SCGI_SOCKET  = rpcSocket;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
    };
  };
}
