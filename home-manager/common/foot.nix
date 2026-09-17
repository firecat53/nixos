{
  config,
  ...
}:
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "Maple Mono NF:size=16";
      };
      scrollback = {
        lines = 100000;
      };
      mouse = {
        hide-when-typing = "yes";
      };
      key-bindings = {
        # Pipe bindings spawn in the shell's OSC 7 cwd, like spawn-terminal;
        # the piped screen text is discarded
        pipe-visible = ''[sh -c "exec ${config.programs.foot.package}/bin/foot ${config.programs.yazi.package}/bin/yazi </dev/null"] Mod4+z'';
      };
    };
  };
}
