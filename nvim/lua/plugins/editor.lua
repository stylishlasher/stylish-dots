return {
  { "folke/which-key.nvim", opts = { preset = "modern" } },

  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
      },
      window = { width = 32 },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false,
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "bash", "css", "html", "json", "lua", "markdown", "markdown_inline",
        "python", "toml", "yaml", "vim", "vimdoc",
      })
    end,
  },
}
