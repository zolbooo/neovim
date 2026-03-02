return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },

  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      highlight = { enable = true },
      indent = {
        enable = true,
        -- Tree-sitter Python indent can aggressively dedent while typing.
        -- Keep Tree-sitter highlighting, but use Neovim's Python indent script.
        disable = { "python" },
      },
    },
    config = function(_, opts)
      local ok_ts, ts = pcall(require, "nvim-treesitter")
      if not ok_ts then
        return
      end

      ts.setup({
        install_dir = opts.install_dir,
      })

      local highlight_enabled = opts.highlight and opts.highlight.enable
      local indent_enabled = opts.indent and opts.indent.enable
      local indent_disable = opts.indent and opts.indent.disable
      if not highlight_enabled and not indent_enabled then
        return
      end

      local function indent_is_disabled(bufnr)
        local filetype = vim.bo[bufnr].filetype
        if type(indent_disable) == "function" then
          local ok, disabled = pcall(indent_disable, filetype, bufnr)
          return ok and disabled or false
        end

        if type(indent_disable) == "table" then
          return vim.list_contains(indent_disable, filetype)
        end

        return false
      end

      local function apply_treesitter(bufnr)
        if highlight_enabled then
          pcall(vim.treesitter.start, bufnr)
        end

        if indent_enabled and not indent_is_disabled(bufnr) then
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      local group = vim.api.nvim_create_augroup("NvimTreesitterCompat", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
          apply_treesitter(args.buf)
        end,
      })

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= "" then
          apply_treesitter(bufnr)
        end
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = "n",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters = {
        terraform_fmt = {
          command = "tofu",
          args = { "fmt", "-" },
          stdin = true,
        },
      },
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier", "jq", stop_after_first = true },
        yaml = { "prettier" },
        markdown = { "prettier" },
        python = { "black" },
        terraform = { "terraform_fmt" },
        sh = { "shfmt" },
      },
    },
  },
}
