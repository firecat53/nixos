{
  programs.gh = {
    enable = true;
    settings = {
      version = 1;
      git_protocol = "ssh";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };

  programs.git = {
    enable = true;
    aliases = {
      pushRemote = "!git push $(git config --get branch.$(git symbolic-ref HEAD --short).pushRemote) +@:$(git config --get branch.$(git symbolic-ref HEAD --short).merge | awk -F / '{print $NF}')";
    };
    delta.enable = true;
    delta.options = {
      features = "line-numbers decorations wooly-mammoth";
      whitespace-error-style = "22 reverse";
      navigate = true;
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
      };
    };
    extraConfig = {
      user = {
        name = "Scott Hansen";
        email = "tech@firecat53.net";
      };
      github = {
        user = "firecat53";
      };
      init = {
        defaultBranch = "main";
      };
      push = {
        default = "current";
      };
      pull = {
        rebase = "false";
      };
      color.branch = {
        current = "yellow reverse";
        local = "yellow";
        remote = "green";
      };
      color.diff = {
        meta = "yellow bold";
        frag = "magenta bold";
        old = "red";
        new = "cyan";
      };
      color.status = {
        added = "yellow";
        changed = "green";
        untracked = "cyan";
      };
    };
    ignores = [
      "*.[oa]"
      "*~"
      "*.swp"
      ".~lock*"
      "*.pyc"
      "*.swo"
      ".cache"
      ".ropeproject"
      "**/doc/tags"
      "venv"
      ".vscode"
      "**/.local/share/containers"
      "**_version.py"
      "/dist/"
    ];
    signing = {
      key = "2BD1E9815C541EA2";
      signByDefault = true;
    };
  };
}
