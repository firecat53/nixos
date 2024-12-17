{pkgs, ...}: {
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;
      undoFile.enable = true;
      searchCase = "smart";

      spellcheck = {
        enable = true;
      };

      lsp = {
        formatOnSave = false;
        lspkind.enable = false;
        lightbulb.enable = false;
        lspsaga.enable = false;
        trouble.enable = false;
        lspSignature.enable = false;
        otter-nvim.enable = false;
        lsplines.enable = false;
        nvim-docs-view.enable = false;
      };

      debugger = {
        nvim-dap = {
          enable = false;
          ui.enable = false;
        };
      };

      # This section does not include a comprehensive list of available language modules.
      # To list all available language module options, please visit the nvf manual.
      languages = {
        enableLSP = true;
        enableFormat = false;
        enableTreesitter = true;
        enableExtraDiagnostics = false;

        # Languages that will be supported in default and maximal configurations.
        nix.enable = true;
        markdown = {
          enable = true;
          format.enable = false;
        };

        # Languages that are enabled in the maximal configuration.
        bash.enable = true;
        clang.enable = true;
        css.enable = true;
        html.enable = true;
        sql.enable = true;
        go.enable = true;
        lua.enable = true;
        python.enable = true;
      };

      visuals = {
        nvim-scrollbar.enable = false;
        nvim-web-devicons.enable = false;
        nvim-cursorline.enable = false;
        cinnamon-nvim.enable = false;
        fidget-nvim.enable = false;

        highlight-undo.enable = false;
        indent-blankline.enable = false;

        # Fun
        cellular-automaton.enable = false;
      };

      statusline = {
        lualine = {
          enable = false;
          theme = "catppuccin";
        };
      };

      theme = {
        enable = true;
        name = "catppuccin";
        style = "mocha";
        transparent = false;
      };

      autopairs.nvim-autopairs.enable = false;

      autocomplete.nvim-cmp.enable = false;
      snippets.luasnip.enable = false;

      filetree = {
        neo-tree = {
          enable = false;
        };
      };

      tabline = {
        nvimBufferline.enable = false;
      };

      treesitter.context.enable = false;

      binds = {
        whichKey.enable = false;
        cheatsheet.enable = false;
      };

      telescope.enable = false;

      git = {
        enable = false;
        gitsigns.enable = false;
      };

      minimap = {
        minimap-vim.enable = false;
        codewindow.enable = false; # lighter, faster, and uses lua for configuration
      };

      dashboard = {
        dashboard-nvim.enable = false;
        alpha.enable = false;
      };

      notify = {
        nvim-notify.enable = false;
      };

      projects = {
        project-nvim.enable = false;
      };

      utility = {
        ccc.enable = false;
        vim-wakatime.enable = false;
        icon-picker.enable = false;
        surround.enable = false;
        diffview-nvim.enable = false;
        images = {
          image-nvim.enable = false;
        };
        preview.markdownPreview = {
          enable = true;
          #alwaysAllowPreview = true; # TODO remove when preview bug is fixed
          filetypes = ["markdown" "vimwiki"];
        };
      };

      notes = {
        obsidian.enable = false; # FIXME: neovim fails to build if obsidian is enabled
        neorg.enable = false;
        orgmode.enable = false;
        mind-nvim.enable = false;
        todo-comments.enable = false;
      };

      terminal = {
        toggleterm = {
          enable = true;
          lazygit.enable = true;
        };
      };

      ui = {
        borders.enable = true;
        noice.enable = false;
        colorizer.enable = false;
        modes-nvim.enable = false; # the theme looks terrible with catppuccin
        illuminate.enable = false;
        breadcrumbs = {
          enable = false;
          navbuddy.enable = false;
        };
        smartcolumn = {
          enable = false;
          setupOpts.custom_colorcolumn = {
            # this is a freeform module, it's `buftype = int;` for configuring column position
            nix = "110";
            ruby = "120";
            java = "130";
            go = ["90" "130"];
          };
        };
        fastaction.enable = false;
      };

      assistant = {
        chatgpt.enable = false;
        copilot = {
          enable = false;
          cmp.enable = true;
        };
      };

      session = {
        nvim-session-manager.enable = false;
      };

      gestures = {
        gesture-nvim.enable = false;
      };

      comments = {
        comment-nvim.enable = false;
      };

      presence = {
        neocord.enable = false;
      };

      extraPlugins = with pkgs.vimPlugins; {
        vimwiki = {
          package = vimwiki;
          setup = ''
            -- Set up vimwiki global variables first
            vim.g.vimwiki_list = {{
              path = '~/docs/family/scott/wiki',
              ext = '.md',
              syntax = 'markdown',
              index = 'Home',
              diary_rel_path = os.date('diary/%Y')
            }}
            vim.g.vimwiki_auto_chdir = 1
            vim.g.vimwiki_folding = ""
            vim.g.vimwiki_global_ext = 0

            vim.api.nvim_create_autocmd("BufWritePost", {
              pattern = "*.md",
              callback = function()
                local wiki_path = vim.fn.expand('~/docs/family/scott/wiki')
                vim.loop.chdir(wiki_path)

                local handle = vim.loop.spawn('git', {
                  args = {'status'},
                  cwd = wiki_path
                }, function(code, signal)
                  if code == 0 then
                    local handle2 = vim.loop.spawn('git', {
                      args = {'add', '.'},
                      cwd = wiki_path
                    }, function(code2, signal2)
                      if code2 == 0 then
                        local commit_msg = string.format('Update: %s', os.date('%Y-%m-%d %H:%M:%S'))
                        vim.loop.spawn('git', {
                          args = {'commit', '-m', commit_msg},
                          cwd = wiki_path
                        })
                      end
                    end)
                  end
                end)
              end,
              group = vim.api.nvim_create_augroup("VimwikiGit", { clear = true })
            })

            -- Map <Leader>j and <Leader>k for Vimwiki diary navigation
            vim.api.nvim_set_keymap('n', '<Leader>j', '<Plug>VimwikiDiaryNextDay', {})
            vim.api.nvim_set_keymap('n', '<Leader>k', '<Plug>VimwikiDiaryPrevDay', {})
          '';
        };
      };
    };
  };
}
