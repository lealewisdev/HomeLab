{ config, pkgs, ... }:
{
  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "25.11";
  home.packages = with pkgs; [ ];
  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
  };

  programs.home-manager.enable = true;
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting "hello"
    '';
    completions.uv = ''
      uv generate-shell-completion fish | source
    '';
  };
  programs.bat.enable = true;
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.btop.enable = true;
  programs.micro.enable = true;
  programs.tmux.enable = true;
  programs.uv.enable = true;
  stylix.targets = {
    bat.enable = true;
    fzf.enable = true;
    btop.enable = true;
    micro.enable = true;
    tmux.enable = true;
    fish.enable = true;
    yazi.enable = true;
  };
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-ctrl-r" ];
    themes = {
      "catppuccin-frappe-lavender" = {
        theme.name = "Catppuccin Frappe Lavender";
        colors = {
          AlertInfo = "#a6d189";
          AlertWarn = "#ef9f76";
          AlertError = "#e78284";
          Annotation = "#babbf1";
          Base = "#c6d0f5";
          Guidance = "#949cbb";
          Important = "#e78284";
          Title = "#babbf1";
        };
      };
    };
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "redacted";
      search_mode = "fuzzy";
    };
  };
}
