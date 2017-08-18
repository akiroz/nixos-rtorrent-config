{ id, enable }: { pkgs, ... }: let
  flood = import ./flood.nix pkgs;
  bash        = "/run/current-system/sw/bin/bash";
  chmod       = "/run/current-system/sw/bin/chmod";
  peerPort    = 40000 + id;
  dhtPort     = 41000 + id;
  floodPort   = 42000 + id;
  workingDir  = "/home/rtorrent/${toString id}";
  rpcSocket   = "${workingDir}/rtorrent.sock";
  session     = "${workingDir}/rtorrent.dtach";
  pidFile     = "${workingDir}/rtorrent.pid";
  rtorrentRC  = pkgs.writeText "rtorrent.rc" ''
    directory.default.set                 = /mnt/storage/rtorrent/data
    session.path.set                      = ${workingDir}
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
    schedule2 = scgi_set_permission, 0, 0, "execute.nothrow = ${chmod}, \"g+w,o=\", ${rpcSocket}"
    execute.nothrow = ${bash}, -c, (cat, "echo -n > ${pidFile} ", (system.pid))
  '';
in {
  networking.firewall = {
    allowedTCPPorts = [ peerPort floodPort ];
    allowedUDPPorts = [ dhtPort ];
  };
  systemd.services = {
    "rtorrent-${toString id}" = let
      kill      = "/run/current-system/sw/bin/kill";
      dtach     = "${pkgs.dtach}/bin/dtach";
      rtorrent  = "${pkgs.rtorrent}/bin/rtorrent";
    in {
      enable = enable;
      preStart = ''
        mkdir -m 0700 -p ${workingDir}
        chown rtorrent ${workingDir}
        if [ -f ${session} ]; then
          rm ${session}
        fi
      '';
      serviceConfig = {
        User = "rtorrent";
        Group = "storage";
        Type = "forking";
        KillMode = "none";
        ExecStop = "${bash} -c '${kill} -s 15 `cat ${pidFile}` || true'";
        ExecStart = "${dtach} -n ${session} -E -z ${rtorrent} -n -o import=${rtorrentRC}";
        Restart = "on-failure";
      };
      environment = {
        TERM = "xterm";
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "local-fs.target" ];
    };
    "flood-${toString id}" = {
      enable = enable;
      serviceConfig = {
        User = "rtorrent";
        WorkingDirectory = "${workingDir}";
        ExecStart = "${pkgs.nodejs}/bin/node ${flood}/server/bin/www";
        Restart = "on-failure";
      };
      environment = {
        NODE_ENV              = "production";
        FLOOD_SERVER_PORT     = toString floodPort;
        RTORRENT_SCGI_SOCKET  = rpcSocket;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "rtorrent-${toString id}.service" ];
    };
  };
}
