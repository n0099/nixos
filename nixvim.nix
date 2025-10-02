{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.nixvim.nixosModules.nixvim ];
  # https://discourse.nixos.org/t/mkmerge-as-the-body-of-a-configuration/9666
  config = lib.mkMerge [
    {
      environment.sessionVariables.EDITOR = "nvim"; # https://github.com/NixOS/nixpkgs/pull/444058
      programs.nixvim.defaultEditor = true;
    }
    {
      programs.nixvim = lib.mkMerge [
        {
          enable = true;
          viAlias = true;
          vimAlias = true;
          colorscheme = "sorbet";
          plugins = {
            trim.enable = true;
            lastplace.enable = true;
            visual-whitespace.enable = true;
            guess-indent.enable = true;
            illuminate.enable = true;
            comment.enable = true;
            fugitive.enable = true;
            nvim-surround.enable = true;
          };
          extraPlugins = with pkgs; [
            vimPlugins.vim-better-whitespace
            vimPlugins.vim-pasta
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
            "after/ftplugin/gitcommit.lua".localOpts.textwidth = 0; # https://unix.stackexchange.com/questions/138148/make-vim-stop-splitting-my-git-commit-messages
            "after/ftplugin/nix.lua".localOpts = {
              # https://github.com/nix-community/nixvim/issues/2418#issuecomment-2413714276
              tabstop = 2; # https://github.com/nix-community/nixvim/pull/3535#discussion_r2191072494
              shiftwidth = 2;
            };
          };
          opts = {
            # https://superuser.com/questions/505937/how-to-set-tab-to-4-spaces-in-vim/505948#505948
            # https://vi.stackexchange.com/questions/4141/how-to-indent-as-spaces-instead-of-tab
            tabstop = 4;
            shiftwidth = 4;
            expandtab = true;
          }
          // {
            undofile = true;
          };
        }
        {
          extraPlugins = with pkgs; [
            (vimUtils.buildVimPlugin {
              name = "indentmini";
              src = fetchFromGitHub {
                owner = "nvimdev";
                repo = "indentmini.nvim";
                rev = "0dc4bc2b3fc763420793e748b672292bc43ee722";
                hash = "sha256-iMQn9eJuwThatTg9aTKhgHQaBc1NV4h/6gGt+fhZG9k=";
              };
            })
          ];
          extraConfigLua = ''
            require('indentmini').setup()
            -- https://github.com/nvimdev/indentmini.nvim/blob/0dc4bc2b3fc763420793e748b672292bc43ee722/README.md#highlight
            -- :h highlight-groups
            vim.cmd.highlight('IndentLine guifg=#333333')
          '';
        }
        {
          plugins = {
            treesitter = {
              enable = true;
              settings.indent.enable = true;
            };
            rainbow-delimiters.enable = true;
          }
          // {
            dropbar.enable = true;
            web-devicons.enable = true;
          };
          autoCmd = [
            {
              # `vim.treesitter.start()` will enable highlight of `nvim-treesitter` and `rainbow-delimiters`
              # or highlights of `rainbow-delimiters` will show on the first buffer update
              # https://neovim.io/doc/user/treesitter.html#vim.treesitter.start()
              # https://neovim.io/doc/user/treesitter.html#vim.treesitter.language.add()
              event = "FileType";
              callback.__raw = ''
                function(args)
                  local lang = vim.treesitter.language.get_lang(args.match)
                  if vim.treesitter.language.add(lang) then
                    vim.treesitter.start(args.buf, lang)
                  end
                end
              '';
            }
          ];
        }
        {
          plugins.lspconfig.enable = true;
          diagnostic.settings = {
            underline = false;
            virtual_text.current_line = false; # https://github.com/neovim/neovim/pull/33517
            virtual_lines.current_line = true;
            update_in_insert = true;
          };
        }
        {
          plugins = {
            treesitter.enable = true;
            lspconfig.enable = true;
            statuscol.enable = true;
            origami.enable = true;
          };
          opts = {
            foldcolumn = "1"; # https://github.com/kevinhwang91/nvim-ufo/issues/4#issuecomment-1157716294
            fillchars = "foldopen:,foldsep: ,foldclose:";
            foldlevelstart = 99; # https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file/26082966#26082966
            # https://github.com/nvim-treesitter/nvim-treesitter/blob/42fc28ba918343ebfd5565147a42a26580579482/README.md#folding
            foldmethod = "expr";
            foldexpr = "v:lua.vim.treesitter.foldexpr()";
          };
          autoCmd = [
            {
              event = "LspAttach";
              callback.__raw = ''
                -- https://neovim.io/doc/user/lsp.html#vim.lsp.foldexpr()
                function(args)
                  local client = vim.lsp.get_client_by_id(args.data.client_id)
                  if client:supports_method('textDocument/foldingRange') then
                    local win = vim.api.nvim_get_current_win()
                    vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
                  end
                end
              '';
            }
          ];
          extraConfigLua = ''
            -- https://stackoverflow.com/questions/74397698/how-to-remove-the-fold-level-numbers-in-vim/78238311#78238311
            local builtin = require('statuscol.builtin')
            require('statuscol').setup({
              setopt = true,
              -- override the default list of segments with:
              -- number-less fold indicator, then signs, then line number & separator
              segments = {
                { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
                { text = { '%s' }, click = 'v:lua.ScSa' },
                {
                  text = { builtin.lnumfunc, ' ' },
                  condition = { true, builtin.not_empty },
                  click = 'v:lua.ScLa',
                },
              },
            })
          '';
        }
        {
          opts = {
            cursorline = true;
            number = true;
            numberwidth = 1;
          };
          plugins = {
            lualine = {
              enable = true;
              settings.theme = "powerline";
            };
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
          autoCmd =
            let
              modesToDisableScreenkey = "{i*,c,cr}*"; # https://neovim.io/doc/user/vimfn.html#mode()
            in
            [
              {
                event = "ModeChanged"; # https://neovim.io/doc/user/autocmd.html#ModeChanged
                pattern = "*:" + modesToDisableScreenkey; # https://neovim.io/doc/user/autocmd.html#autocmd-pattern
                callback.__raw = ''
                  function()
                    vim.g.screenkey_statusline_component = false
                  end
                '';
              }
              {
                event = "ModeChanged";
                pattern = modesToDisableScreenkey + ":*";
                callback.__raw = ''
                  function()
                    vim.g.screenkey_statusline_component = true
                  end
                '';
              }
            ];
          extraConfigLua = ''
            -- https://github.com/NStefan002/screenkey.nvim/blob/16390931d847b1d5d77098daccac4e55654ac9e2/README.md#-how-to-use
            vim.g.screenkey_statusline_component = true
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
          plugins.gitsigns = {
            enable = true;
            settings = {
              current_line_blame = true;
              current_line_blame_opts.delay = 100;
            };
          };
          extraPlugins = [
            pkgs.vimPlugins.nvim-hlslens
            pkgs.vimPlugins.nvim-scrollbar
          ];
          extraConfigLua = ''
            -- https://github.com/petertriho/nvim-scrollbar/blob/5b103ef0fd2e8b9b4be3878ed38d224522192c6c/README.md#setup
            require('scrollbar').setup()
            require('scrollbar.handlers.search').setup()
            require('scrollbar.handlers.gitsigns').setup()
          '';
        }
        {
          plugins = {
            nvim-autopairs.enable = true;
            coq-nvim = {
              enable = true;
              installArtifacts = true;
              settings.auto_start = "shut-up";
            };
          };
          extraConfigLua = ''
            -- https://github.com/windwp/nvim-autopairs/blob/23320e75953ac82e559c610bec5a90d9c6dfa743/README.md#mapping-cr
            local remap = vim.api.nvim_set_keymap
            local npairs = require('nvim-autopairs')

            npairs.setup({ map_bs = false, map_cr = false })

            vim.g.coq_settings = { keymap = { recommended = false } }

            -- these mappings are coq recommended mappings unrelated to nvim-autopairs
            remap('i', '<esc>', [[pumvisible() ? "<c-e><esc>" : "<esc>"]], { expr = true, noremap = true })
            remap('i', '<c-c>', [[pumvisible() ? "<c-e><c-c>" : "<c-c>"]], { expr = true, noremap = true })
            remap('i', '<tab>', [[pumvisible() ? "<c-n>" : "<tab>"]], { expr = true, noremap = true })
            remap('i', '<s-tab>', [[pumvisible() ? "<c-p>" : "<bs>"]], { expr = true, noremap = true })

            -- skip it, if you use another global object
            _G.MUtils= {}

            MUtils.CR = function()
              if vim.fn.pumvisible() ~= 0 then
                if vim.fn.complete_info({ 'selected' }).selected ~= -1 then
                  return npairs.esc('<c-y>')
                else
                  return npairs.esc('<c-e>') .. npairs.autopairs_cr()
                end
              else
                return npairs.autopairs_cr()
              end
            end
            remap('i', '<cr>', 'v:lua.MUtils.CR()', { expr = true, noremap = true })

            MUtils.BS = function()
              if vim.fn.pumvisible() ~= 0 and vim.fn.complete_info({ 'mode' }).mode == 'eval' then
                return npairs.esc('<c-e>') .. npairs.autopairs_bs()
              else
                return npairs.autopairs_bs()
              end
            end
            remap('i', '<bs>', 'v:lua.MUtils.BS()', { expr = true, noremap = true })
          '';
        }
        {
          extraPlugins = [ pkgs.vimPlugins.treewalker-nvim ];
          extraConfigLua = ''
            require('treewalker').setup()
            -- https://github.com/aaronik/treewalker.nvim/blob/e339e81951e96147b57f30abbb76a67d71b809ba/README.md#mapping
            vim.keymap.set({ 'n', 'v' }, '<C-k>', '<cmd>Treewalker Up<cr>', { silent = true })
            vim.keymap.set({ 'n', 'v' }, '<C-j>', '<cmd>Treewalker Down<cr>', { silent = true })
            vim.keymap.set({ 'n', 'v' }, '<C-h>', '<cmd>Treewalker Left<cr>', { silent = true })
            vim.keymap.set({ 'n', 'v' }, '<C-l>', '<cmd>Treewalker Right<cr>', { silent = true })
          '';
        }
        {
          extraPlugins = [ pkgs.vimPlugins.nvim-gomove ];
          extraConfigLua = "require('gomove').setup()";
        }
      ];
    }
    {
      programs.nixvim = {
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
        '';
        # https://www.mitchellhanberg.com/modern-format-on-save-in-neovim/
        autoGroups.lsp.clear = true;
        autoCmd = [
          {
            event = "LspAttach";
            group = "lsp";
            callback.__raw = ''
              function(args)
                vim.api.nvim_create_autocmd('BufWritePre', {
                  buffer = args.buf,
                  callback = function()
                    vim.lsp.buf.format { async = false, id = args.data.client_id }
                  end,
                })
              end
            '';
          }
        ];
      };
      environment.systemPackages = with pkgs; [
        nixd
        nixfmt-rfc-style
      ];
    }
  ];
}
