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
  };

  # Transcripts, plans and settings synced via syncthing so /resume works on
  # both desktops. settings.json stays mutable so /config, /permissions and
  # /auto-mode-setup can write it
  home.file = {
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${claudeState}/settings.json";
    ".claude/projects".source = config.lib.file.mkOutOfStoreSymlink "${claudeState}/projects";
    ".claude/plans".source = config.lib.file.mkOutOfStoreSymlink "${claudeState}/plans";
  };
}
