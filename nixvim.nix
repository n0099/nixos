{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.nixvim.nixosModules.nixvim ];
  programs.nixvim = lib.mkMerge [
    {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
      colorscheme = "desert";
      plugins = {
        # leap.enable = true;
        trim.enable = true;
        lastplace.enable = true;
        visual-whitespace.enable = true;
        guess-indent.enable = true;
        illuminate.enable = true;
        fugitive.enable = true;
        gitsigns = {
          enable = true;
          settings = {
            current_line_blame = true;
            current_line_blame_opts.delay = 100;
          };
        };
        coq-nvim = {
          enable = true;
          installArtifacts = true;
          settings.auto_start = "shut-up";
        };
      };
      extraPlugins = with pkgs; [
        vimPlugins.vim-better-whitespace
        vimPlugins.vim-pasta
        (vimUtils.buildVimPlugin {
          name = "indentmini";
          src = fetchFromGitHub {
            owner = "nvimdev";
            repo = "indentmini.nvim";
            rev = "0dc4bc2b3fc763420793e748b672292bc43ee722";
            hash = "sha256-iMQn9eJuwThatTg9aTKhgHQaBc1NV4h/6gGt+fhZG9k=";
          };
        })
        (vimUtils.buildVimPlugin {
          name = "auto-indent";
          src = fetchFromGitHub {
            owner = "VidocqH";
            repo = "auto-indent.nvim";
            rev = "46801cf8857d42a20a73c40b0a5d3dfe8b2b6192";
            hash = "sha256-dubpVupLfc81Jvb4woSQ63n2+VsJCRjnvDzkFTQE2MQ=";
          };
        })
      ];
      files = {
        "after/ftplugin/nix.lua" = {
          # https://github.com/nix-community/nixvim/issues/2418#issuecomment-2413714276
          localOpts = {
            # https://github.com/nix-community/nixvim/pull/3535#discussion_r2191072494
            tabstop = 2;
            shiftwidth = 2;
          };
        };
      };
      opts = {
        # https://superuser.com/questions/505937/how-to-set-tab-to-4-spaces-in-vim/505948#505948
        # https://vi.stackexchange.com/questions/4141/how-to-indent-as-spaces-instead-of-tab
        tabstop = 4;
        shiftwidth = 4;
        expandtab = true;
      };
    }
    {
      plugins = {
        treesitter = {
          enable = true;
          settings.indent.enable = true;
        };
        rainbow-delimiters.enable = true;
        dropbar.enable = true;
      };
      extraConfigLua = ''
        -- `vim.treesitter.start()` will enable highlight of `nvim-treesitter` and `rainbow-delimiters`
        -- or highlights of `rainbow-delimiters` will show on the first buffer update
        -- https://neovim.io/doc/user/treesitter.html#vim.treesitter.start()
        -- https://neovim.io/doc/user/treesitter.html#vim.treesitter.language.add()
        vim.api.nvim_create_autocmd('FileType', {
          callback = function(args)
            local lang = vim.treesitter.language.get_lang(args.match)
            if vim.treesitter.language.add(lang) then
              vim.treesitter.start(args.buf, lang)
            end
          end
        })
        -- https://github.com/nvimdev/indentmini.nvim/blob/0dc4bc2b3fc763420793e748b672292bc43ee722/README.md#config
        require('indentmini').setup({ only_current = true })
      '';
    }
    {
      plugins.lspconfig.enable = true;
      extraConfigLua = ''
        -- https://github.com/NixOS/nixfmt/blob/1f2589cb7198529c6c1eec9699eccd4d507d3600/README.md#neovim--nixd
        local nvim_lsp = require('lspconfig')
        nvim_lsp.nixd.setup({
           settings = {
              nixd = {
                 formatting = {
                    command = { 'nixfmt' },
                 },
              },
           },
        })

        -- https://www.mitchellhanberg.com/modern-format-on-save-in-neovim/
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('lsp', { clear = true }),
          callback = function(args)
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format { async = false, id = args.data.client_id }
              end,
            })
          end
        })
      '';
    }
    {
      opts = {
        cursorline = true;
        number = true;
      };
      plugins = {
        lualine.enable = true;
        lualine.settings.theme = "powerline";
        modicator.enable = true;
      };
      extraPlugins = with pkgs; [
        (vimUtils.buildVimPlugin {
          name = "screenkey";
          src = fetchFromGitHub {
            owner = "NStefan002";
            repo = "screenkey.nvim";
            rev = "16390931d847b1d5d77098daccac4e55654ac9e2";
            hash = "sha256-EGyIkWcQbCurkBbeHpXvQAKRTovUiNx1xqtXmQba8Gg=";
          };
        })
      ];
      extraConfigLua = ''
        -- https://github.com/NStefan002/screenkey.nvim/blob/16390931d847b1d5d77098daccac4e55654ac9e2/README.md#-how-to-use
        vim.g.screenkey_statusline_component = true
        -- https://neovim.io/doc/user/vimfn.html#mode()
        -- https://neovim.io/doc/user/autocmd.html#autocmd-pattern
        local modes_to_disable_screenkey = '{i*,c,cr}*'
        -- https://neovim.io/doc/user/autocmd.html#ModeChanged
        vim.api.nvim_create_autocmd('ModeChanged', {
          pattern = '*:' .. modes_to_disable_screenkey,
          callback = function()
            vim.g.screenkey_statusline_component = false
          end
        })
        vim.api.nvim_create_autocmd('ModeChanged', {
          pattern = modes_to_disable_screenkey .. ':*',
          callback = function()
            vim.g.screenkey_statusline_component = true
          end
        })
        require('screenkey').setup({
          clear_after = math.huge,
          filter = function(keys)
            return vim.iter(keys)
              :filter(function(k)
                return k.key ~= '<LeftDrag>' -- https://neovim.io/doc/user/gui.html#%3CLeftDrag%3E
              end)
              :totable()
          end,
        })

        -- https://github.com/nvim-lualine/lualine.nvim/blob/master/README.md#default-configuration
        require('lualine').setup({
          sections = {
            lualine_c = {
              'filename',
              function()
                return require('screenkey').get_keys()
              end,
            },
            lualine_x = {
              { 'encoding', show_bomb = true }, -- https://github.com/nvim-lualine/lualine.nvim/blob/master/README.md#encoding-component-options
              'fileformat',
              'filetype',
            },
            lualine_z = {
              'location',
              'lsp_status',
            },
          },
        })
      '';
    }
    {
      extraPlugins = [ pkgs.vimPlugins.ultimate-autopair-nvim ];
      extraConfigLua = "require('ultimate-autopair').setup()";
    }
  ];
}
