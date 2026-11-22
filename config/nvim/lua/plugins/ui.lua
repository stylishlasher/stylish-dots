return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
   ____  __        ___      __  
  / __/ / /_ __ __/ (_)___ / /  
 _\ \  / __// // / / /(_-</ _ \ 
/___/  \__/ \_, /_/_//___/_//_/ 
           /___/   lazyvim-stylish ]],
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "recent_files", cwd = true, limit = 8, padding = 1 },
          { section = "startup" },
        },
      },
      indent = { enabled = true },
      scroll = { enabled = true },
      words = { enabled = true },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.globalstatus = true
      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "│", right = "│" }
    end,
  },

  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = false,
        diagnostics = "nvim_lsp",
        separator_style = "thin",
        show_buffer_close_icons = false,
      },
    },
  },

  {
    "folke/noice.nvim",
    opts = {
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },
}
