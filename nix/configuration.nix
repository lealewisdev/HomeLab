{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    useXkbConfig = false;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs = {
    package = pkgs.zfs_unstable;
    forceImportRoot = false;
    extraPools = [ "storage" ];
  };
  boot.loader.grub.device = "/dev/sda";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages;
  boot.kernelModules = [
    "bluetooth"
    "iso_socket"
  ];
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.accept_ra_rt_info_max_plen" = 64;
    "net.ipv6.conf.all.disable_ipv6" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.accept_ra" = 2;
    "net.ipv6.conf.eno2.mc_forwarding" = 1;
    "net.ipv4.ip_forward" = 1;
  };
  boot.blacklistedKernelModules = [
    "dvb_core"
    "dvb_usb_rtl2832u"
    "dvb_usb_rtl28xxu"
    "dvb_usb_v2"
    "r820t"
    "rtl2830"
    "rtl2832"
    "rtl2832_sdr"
    "rtl2838"
  ];
  boot.extraModprobeConfig = ''
    install dvb_core /bin/false
    install dvb_usb_rtl2832u /bin/false
    install dvb_usb_rtl28xxu /bin/false
    install dvb_usb_v2 /bin/false
    install r820t /bin/false
    install rtl2830 /bin/false
    install rtl2832 /bin/false
    install rtl2832_sdr /bin/false
    install rtl2838 /bin/false
  '';

  networking.hostName = "Yuki";
  networking.hostId = "da2d7801";
  networking.nftables.enable = true;
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [
    "wpan0" # Matter
    "br-+"
  ];
  networking.enableIPv6 = true;
  networking.firewall.allowedTCPPorts = [
    80 # Traefik
    443 # Traefik
    8123 # HA
    6052 # ESPHome
    7586 # OTBR
    8095 # MA
    8088 # Sendspin
    8080 # Traefik
    8081 # OTBR
    1883 # Mosquito
    8085 # Z2M
    5580 # Matter
    10300 # ONNX
    6566 # SANED
    39080 # Forgejo Runner
    39081 # Forgejo Runner
  ];
  networking.firewall.interfaces.docker0.allowedTCPPorts = [
    631 # Cups
  ];
  networking.firewall.allowedUDPPorts = [
    16262 # Zomboid
    16261 # Zomboid
    5353 # mDNS
  ];
  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
  security.rtkit.enable = true;
  users.users.admin = {
    isNormalUser = true;
    description = "admin";
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "audio"
      "video"
      "lp"
      "bluetooth"
      "pipewire"
      "scanner"
    ];
    shell = pkgs.fish;
    home = "/home/admin";
    packages = with pkgs; [
      tree
    ];
  };
  users.users.admin.homeMode = "700";
  users.users.admin.linger = true;

  users.users.immi = {
    isNormalUser = true;
    home = "/home/immi";
    homeMode = "700";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6rkmXv+X5VCHptOFvugV5vb0bx4gbWRCFqDYDDC2Ec Bebo"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+40siS8v18dyCOiarFxMT1y3Nzii899X595OckUEqw Denken"
    ];
  };

  hardware.sane.enable = true;
  hardware.enableAllFirmware = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        JustWorksRepairing = "always";
        ControllerMode = "dual";
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
  hardware.printers = {
    ensurePrinters = [
      {
        name = "Canon_SELPHY";
        location = "Home";
        deviceUri = "gutenprint53+usb://canon-cp1500/C225111301307902";
        model = "gutenprint.5.3://canon-cp1500/expert";
        ppdOptions = {
          PageSize = "Postcard";
        };
      }
    ];
    ensureDefaultPrinter = "Canon_SELPHY";
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ];
    listenAddresses = [ "*:631" ];
    allowFrom = [
      "localhost"
      "10.100.0.0/24"
    ];
    browsing = true;
    defaultShared = true;
  };
  services.saned.enable = true;
  services.saned.extraConfig = ''
    172.31.2.0/24
    data_portrange = 10000 - 10100
  '';
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  security.pam.services.sshd.unixAuth = lib.mkForce true;
  services.libinput.enable = true;
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "security" = "user";
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "hosts allow" = "192.168.1. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
      };
      "public" = {
        "path" = "/home/admin/miku";
        "browsable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
    interface = "eno2";
  };
  services.avahi = {
    enable = true;
    reflector = true;
    nssmdns4 = true;
    nssmdns6 = true;
    ipv4 = true;
    ipv6 = true;
    openFirewall = true;
    cacheEntriesMax = 4096;
    extraConfig = ''
      [reflector]
        reflect-filters=_matter._tcp.local,_matterc._udp.local
    '';
  };
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    systemWide = false;
    pulse.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    wireplumber = {
      enable = true;
      extraConfig = {
        "10-disable-seat-monitoring" = {
          "wireplumber.profiles" = {
            "main" = {
              "monitor.bluez.seat-monitoring" = "disabled";
            };
          };
        };
        "11-bluetooth-policy" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.roles" = [
              "a2dp_sink"
              "a2dp_source"
              "headset_head_unit"
              "headset_audio_gateway"
            ];
          };
        };
      };
    };
  };

  sops.defaultSopsFile = ./secrets/example.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.example_key = { };

  systemd.user.services.wireplumber.environment = {
    "DBUS_SESSION_BUS_ADDRESS" = "unix:path=/run/user/1000/bus";
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    wget
    _7zz
    unar
    xz
    avahi
    bluez-tools
    ethtool
    gcc
    git
    rsync
    sane-backends
    yq
    home-manager
    jq
    sops
    (python314.withPackages (
      ps: with ps; [
        requests
        docker # community.docker.docker_login also needs the Docker SDK
      ]
    ))
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.git.enable = true;
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # provides libstdc++.so.6
    ];
  };

  stylix = {
    enable = true;
    autoEnable = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
    daemon.settings = {
      data-root = "/mnt/sata/docker";
      default-address-pools = [
        {
          base = "10.100.0.0/16";
          size = 24;
        }
      ];
      registry-mirrors = [ "https://mirror.gcr.io" ];
    };
    extraOptions = "--iptables=true";
  };

  systemd.services.docker.serviceConfig.TasksMax = "infinity";
  systemd.services.docker = {
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
  };

  ### DO NOT EDIT BELOW THIS LINE ###
  system.stateVersion = "25.11";
}
