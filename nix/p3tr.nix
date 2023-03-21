{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.p3tr;

  isAbsolutePath = v: isString v && substring 0 1 v == "/";
  isSecret = v: isAttrs v && v ? _secret && isAbsolutePath v._secret;

  absolutePath = with types;
    mkOptionType {
      name = "absolutePath";
      description = "absolute path";
      descriptionClass = "noun";
      check = isAbsolutePath;
      inherit (str) merge;
    };

  secret = mkOptionType {
    name = "secret";
    description = "secret value";
    descriptionClass = "noun";
    check = isSecret;
    nestedTypes = { _secret = absolutePath; };
  };

  elixirValue = let
    elixirValue' = with types;
      nullOr (oneOf [
        bool
        int
        float
        str
        (attrsOf elixirValue')
        (listOf elixirValue')
      ]) // {
        description = "Elixir value";
      };
  in elixirValue';

  replaceSec = let
    replaceSec' = { }@args:
      v:
      if isAttrs v then
        if v ? _secret then
          if isAbsolutePath v._secret then
            sha256 v._secret
          else
            abort "Invalid secret path (_secret = ${v._secret})"
        else
          mapAttrs (_: val: replaceSec' args val) v
      else if isList v then
        map (replaceSec' args) v
      else
        v;
  in replaceSec' { };

  format = pkgs.formats.elixirConf { };
  configFile = format.generate "config.exs"
    (replaceSec (attrsets.updateManyAttrsByPath [ ] cfg.config));

  cookieWrapper = name:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        RELEASE_COOKIE="''${RELEASE_COOKIE:-$(<"''${RUNTIME_DIRECTORY:-/run/p3tr}/cookie")}" \
          exec "${cfg.package}/bin/${name}" "$@"
      '';
    };

  p3tr = cookieWrapper "p3tr";

  writeShell = { name, text, runtimeInputs ? [ ] }:
    pkgs.writeShellApplication { inherit name text runtimeInputs; }
    + "/bin/${name}";

  genScript = writeShell {
    name = "p3tr-gen-cookie";
    runtimeInputs = with pkgs; [ coreutils util-linux ];
    text = ''
      install -m 0400 \
        -o ${escapeShellArg cfg.user} \
        -g ${escapeShellArg cfg.group} \
        <(dd if=/dev/urandom bs=16 count=1 iflag=fullblock status=none | hexdump -e '16/1 "%02x"') \
        "$RUNTIME_DIRECTORY/cookie"
    '';
  };

  copyScript = writeShell {
    name = "p3tr-copy-cookie";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      install -m 0400 \
        -o ${escapeShellArg cfg.user} \
        -g ${escapeShellArg cfg.group} \
        ${escapeShellArg cfg.dist.cookie._secret} \
        "$RUNTIME_DIRECTORY/cookie"
    '';
  };

  sha256 = builtins.hashString "sha256";

  configScript = writeShell {
    name = "p3tr-config";
    runtimeInputs = with pkgs; [ coreutils replace-secret ];
    text = ''
      cd "$RUNTIME_DIRECTORY"
      tmp="$(mktemp config.exs.XXXXXXXXXX)"
      trap 'rm -f "$tmp"' EXIT TERM
      cat ${escapeShellArg configFile} >"$tmp"
      ${concatMapStrings (file: ''
        replace-secret ${escapeShellArgs [ (sha256 file) file ]} "$tmp"
      '') secretPaths}
      chown ${escapeShellArg cfg.user}:${escapeShellArg cfg.group} "$tmp"
      chmod 0400 "$tmp"
      mv -f "$tmp" config.exs
    '';
  };

  secretPaths = catAttrs "_secret" (collect isSecret cfg.config);
in {
  options = {
    services.p3tr = {
      enable = mkEnableOption (mdDoc "P3tr Discord bot");

      user = mkOption {
        type = types.nonEmptyStr;
        default = "p3tr";
        description = mdDoc "User account under which p3tr runs.";
      };

      group = mkOption {
        type = types.nonEmptyStr;
        default = "p3tr";
        description = mdDoc "Group account under which p3tr runs.";
      };

      stateDir = mkOption {
        type = types.nonEmptyStr;
        default = "/var/lib/p3tr";
        readOnly = true;
        description = mdDoc "Directory where p3tr will save state.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.p3tr;
        defaultText = literalExpression "pkgs.p3tr";
        description = mdDoc "P3tr package to use.";
      };

      dist = {
        cookie = mkOption {
          type = types.nullOr secret;
          default = null;
          example = { _secret = "/var/lib/secrets/p3tr/releaseCookie"; };
          description = mdDoc ''
            Erlang release cookie.
            If set to `null`, a temporary random cookie will be generated.
          '';
        };
      };

      tokenFile = mkOption {
        type = types.nullOr absolutePath;
        default = null;
        example = "/var/lib/secrets/p3tr/token";
      };

      config = mkOption {
        description = mdDoc ''
          Config

          Settings containing secret data should be set to an attribute set containing the
          attribute `_secret` - a string pointing to a file containing the value the option
          should be set to.
        '';

        type = types.submodule {
          freeformType = format.type;
          options = {
            ":nostrum" = {
              ":token" = mkOption {
                type = secret;
                description = "Discord bot token";
                default = cfg.tokenFile;
              };
            };
            ":p3tr" = {
              "P3tr.Repo" = mkOption {
                type = elixirValue;
                default = {
                  socket_dir = "/run/postgresql";
                  username = cfg.user;
                  database = "p3tr";
                };
                defaultText = literalExpression ''
                  {
                    adapter = (pkgs.formats.elixirConf { }).lib.mkRaw "Ecto.Adapters.Postgres";
                    socket_dir = "/run/postgresql";
                    username = config.services.p3tr.user;
                    database = "p3tr";
                  }
                '';
                description = mdDoc ''
                  Database configuration.
                  Refer to
                  <https://hexdocs.pm/ecto_sql/Ecto.Adapters.Postgres.html#module-connection-options>
                  for options.
                '';
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    users = {
      users."${cfg.user}" = {
        description = "p3tr user";
        group = cfg.group;
        isSystemUser = true;
      };
      groups."${cfg.group}" = { };
    };

    services.postgresql = {
      enable = true;
      ensureUsers = [{
        name = "p3tr";
        ensurePermissions."DATABASE p3tr" = "ALL PRIVILEGES";
      }];
      ensureDatabases = [ "p3tr" ];
    };

    systemd.services.p3tr-config = {
      description = "P3tr configuration";
      reloadTriggers = [ configFile ] ++ secretPaths;

      serviceConfig = {
        PropagateReloadTo = [ "p3tr.service" ];
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";

        RuntimeDirectory = "p3tr";
        RuntimeDirectoryMode = "0711";

        ExecStart =
          (if cfg.dist.cookie == null then [ genScript ] else [ copyScript ])
          ++ [ configScript ];
        ExecReload = [ configScript ];
      };
    };

    systemd.services.p3tr = {
      description = "P3tr Discord bot";

      bindsTo = [ "p3tr-config.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      after =
        [ "p3tr-config.service" "network.target" "network-online.target" ];

      environment = { P3TR_CONFIG_PATH = "%t/p3tr/config.exs"; };

      #environment
      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        UMask = "0077";

        RuntimeDirectory = "p3tr";
        RuntimeDirectoryMode = "0711";
        RuntimeDirectoryPreserve = true;
        StateDirectory = "p3tr";
        StateDirectoryMode = "0700";

        BindReadOnlyPaths = [ "/etc/hosts" "/etc/resolv.conf" ];

        ExecStartPre =
          "${p3tr}/bin/p3tr eval 'P3tr.ReleaseTasks.run(\"migrate\")'";
        ExecStart = "${p3tr}/bin/p3tr start";

        ProtectProc = "noaccess";
        ProcSubset = "pid";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateIPC = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;

        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;

        NoNewPrivileges = true;
        SystemCallFilter = [ "@system-service" "~@privileged" "@chown" ];
        SystemCallArchitectures = "native";

        DeviceAllow = null;
        DevicePolicy = "closed";

        SocketBindDeny = "any";

        ProtectSystem = "strict";
      };
    };

    environment.systemPackages = [ p3tr ];
  };
}
