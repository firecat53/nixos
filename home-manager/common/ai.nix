{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.unstable.claude-code
    pkgs.unstable.files-to-prompt
    (pkgs.unstable.llm.withPlugins {
      llm-anthropic = true;
    })
  ];
}
