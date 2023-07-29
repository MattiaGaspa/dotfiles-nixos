{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Boot options
  boot = {
    kernelPackages = pkgs.linuxPackages_zen; # Use the zen flavour of the kernel
    
    # Bootloader options
    loader = {
       systemd-boot.enable = false; # Disable systemd-boot
       
       # Grub options
       grub = {
         enable = true; # Use GRUB instead
         useOSProber = true; # With OSProber
         efiSupport = true; # And EFI
         device = "nodev";
       };

       # Efi options
       efi = {
         canTouchEfiVariables = true;
         efiSysMountPoint = "/boot/efi"; # EFI partition mountpoint
       };
    };
  };

  networking = {
    # Define your hostname
    hostName = "nixos";
    # Define nameservers
    nameservers = [ "192.168.178.41" "1.1.1.1" "8.8.8.8" ];
    
    # Use networkmanager
    networkmanager.enable = true;
    
    # Disable rpfilter to route all traffic through the wireguard tunnel (too lazy to adapt rpfilter)
    firewall.checkReversePath = false;
  };
  
  services = {
    # Xorg options
    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ]; # Use amd drivers
      libinput.enable = true;

      layout = "it"; # Use it keyboard
      xkbVariant = ""; # Enable touchpad support (enabled default in most desktopManager)

      # DisplayManager options
      displayManager.sddm.enable = true; # Use sddm display manager
      desktopManager.plasma5.enable = true; # Use plasma desktop
    };

    # Pipewire options
    pipewire = {
      enable = true;
      
      alsa.enable = true;
      alsa.support32Bit = true;
      
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Enable flatpak support
    flatpak.enable = true;

    # Disable printer support
    printing.enable = false;

    # Enable tlp and auto-cpufreq
    # tlp.enable = true;
    # power-profiles-daemon.enable = false; # Needed because conflict with tlp
    auto-cpufreq.enable = true;
    
    # For Samba
    gvfs.enable = true;
  };

  # Set time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n = {
    # Set locale settings
    defaultLocale = "it_IT.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "it_IT.UTF-8";
      LC_IDENTIFICATION = "it_IT.UTF-8";
      LC_MEASUREMENT = "it_IT.UTF-8";
      LC_MONETARY = "it_IT.UTF-8";
      LC_NAME = "it_IT.UTF-8";
      LC_NUMERIC = "it_IT.UTF-8";
      LC_PAPER = "it_IT.UTF-8";
      LC_TELEPHONE = "it_IT.UTF-8";
      LC_TIME = "it_IT.UTF-8";
    };
  };

  # Enable hardware acceleration
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.hip}"
  ];
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
    amdvlk
  ];
  # For 32 bit applications 
  # Only available on unstable
  hardware.opengl.extraPackages32 = with pkgs; [
    driversi686Linux.amdvlk
  ];

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Install Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  # Configure console keymap
  console.keyMap = "it2";

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Define a mattia's account
  users.users.mattia = {
    isNormalUser = true;
    description = "Mattia Gasparotto";
    extraGroups = [ "audio" "networkmanager" "video" "wheel" ];
    packages = with pkgs; [
      firefox
      kate
      thunderbird
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Nix package manager configuration
  nix = {
    settings ={
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 2d";
    };
    package = pkgs.nixVersions.unstable;    # Enable nixFlakes on system
    #             registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs          = true
      keep-derivations      = true
    '';
  };
  nixpkgs.config.allowUnfree = true;        # Allow proprietary software.

  # Setup configuration files in /etc
  environment.etc = {
    # Auto-cpufreq
    "auto-cpufreq.conf".text = ''
      # settings for when connected to a power source
      [charger]
      # see available governors by running: cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
      # preferred governor.
      governor = performance

      # minimum cpu frequency (in kHz)
      # example: for 800 MHz = 800000 kHz --> scaling_min_freq = 800000
      # see conversion info: https://www.rapidtables.com/convert/frequency/mhz-to-hz.html
      # to use this feature, uncomment the following line and set the value accordingly
      # scaling_min_freq = 800000

      # maximum cpu frequency (in kHz)
      # example: for 1GHz = 1000 MHz = 1000000 kHz -> scaling_max_freq = 1000000
      # see conversion info: https://www.rapidtables.com/convert/frequency/mhz-to-hz.html
      # to use this feature, uncomment the following line and set the value accordingly
      # scaling_max_freq = 1000000

      # turbo boost setting. possible values: always, auto, never
      turbo = auto

      # settings for when using battery power
      [battery]
      # see available governors by running: cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
      # preferred governor
      governor = powersave

      # minimum cpu frequency (in kHz)
      # example: for 800 MHz = 800000 kHz --> scaling_min_freq = 800000
      # see conversion info: https://www.rapidtables.com/convert/frequency/mhz-to-hz.html
      # to use this feature, uncomment the following line and set the value accordingly
      # scaling_min_freq = 800000

      # maximum cpu frequency (in kHz)
      # see conversion info: https://www.rapidtables.com/convert/frequency/mhz-to-hz.html
      # example: for 1GHz = 1000 MHz = 1000000 kHz -> scaling_max_freq = 1000000
      # to use this feature, uncomment the following line and set the value accordingly
      # scaling_max_freq = 1000000

      # turbo boost setting. possible values: always, auto, never
      turbo = auto
    '';
  };

  # Do not touch
  system = {                                # NixOS settings
    # autoUpgrade = {                         # Allow auto update (not useful in flakes)
    #   enable = true;
    #   channel = "https://nixos.org/channels/nixos-unstable";
    # };
    
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    stateVersion = "22.11";
  };
}
