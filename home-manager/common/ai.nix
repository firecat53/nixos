{
  config,
  pkgs,
  ...
}:
let
  claudeState = "${config.home.homeDirectory}/docs/family/scott/src/state/claude";
in
{
  home.packages = [
    pkgs.unstable.files-to-prompt
    (pkgs.unstable.llm.withPlugins {
      llm-anthropic = true;
    })
  ];

  sops.secrets.hass-mcp-url = { };

  programs.claude-code = {
    enable = true;
    # Expanded in the hass and nixos repos' .mcp.json; scoped to claude, not
    # every shell
    package = pkgs.writeShellScriptBin "claude" ''
      export HASS_MCP_URL="$(< ${config.sops.secrets.hass-mcp-url.path})"
      exec ${pkgs.unstable.claude-code}/bin/claude "$@"
    '';
    context = ''
      # Global Instructions

      - **NixOS user**: Don't run package manager commands (pacman, apt, pip, etc.) to check if tools are installed — they will fail or be irrelevant. Use web search to find documentation for tools that aren't available locally.
    '';
    settings = {
      model = "opus";
      effortLevel = "high";
      tui = "fullscreen";
      voice.enabled = false;
      voiceEnabled = false;
      agentPushNotifEnabled = true;
      awaySummaryEnabled = false;
      enabledMcpjsonServers = [ "home-assistant" ];
      permissions = {
        defaultMode = "auto";
        allow = [
          "Bash(dig +short *)"
          "Bash(getent ahostsv4 *)"
        ];
      };
      autoMode = {
        allow = [
          "$defaults"
          "Bash(make test:*)"
          "Bash(make man)"
          "Bash(make venv)"
          "Bash(gh repo view:*)"
        ];
        soft_deny = [
          "$defaults"
          "Bash(hatch publish:*)"
          "Bash(bw:*)"
        ];
      };
      enabledPlugins = {
        "gopls-lsp@claude-plugins-official" = false;
        "lua-lsp@claude-plugins-official" = true;
        "rust-analyzer-lsp@claude-plugins-official" = false;
      };
    };
  };

  # Session transcripts and plans synced via syncthing so /resume works on
  # both desktops
  home.file = {
    ".claude/projects".source = config.lib.file.mkOutOfStoreSymlink "${claudeState}/projects";
    ".claude/plans".source = config.lib.file.mkOutOfStoreSymlink "${claudeState}/plans";
  };
}
