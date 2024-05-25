{
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
      safe = {
        directory = "/home/firecat53/nixos/nixos/.git";
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

  ## GH github CLI tool
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

  ## gh-dash
  programs.gh-dash = {
    enable = true;
    settings = {
      prSections = [
        {
          title = "Open PRs";
          filters = "is:open user:firecat53";
        }
        {
          title = "Needs My Review";
          filters = "is:open review-requested:@me";
        }
        {
          title = "My PRs";
          filters = "is:open author:@me";
        }
      ];
      issuesSections = [
        {
          title = "Bitwarden-menu";
          filters = "is:open repo:firecat53/bitwarden-menu";
        }
        {
          title = "Keepmenu";
          filters = "is:open repo:firecat53/keepmenu";
        }
        {
          title = "Networkmanager-Dmenu";
          filters = "is:open repo:firecat53/networkmanager-dmenu";
        }
        {
          title = "Urlscan";
          filters = "is:open repo:firecat53/urlscan";
        }
        {
          title = "Watson-Dmenu";
          filters = "is:open repo:firecat53/watson-dmenu";
        }
      ];
      defaults = {
        view = "issues";
        layout = {
          issues = {};
          prs = {};
        };
        preview = {
          open = true;
          width = 60;
        };
      };
      pager = {
        diff = "delta";
      };
      repoPaths = {
        ":owner/:repo" = "~/.local/tmp/:repo";
        "firecat53/*" = "~/docs/family/scott/src/projects/*";
      };
    };
  };

}
