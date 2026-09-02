return {
  {
    "folke/tokyonight.nvim",
    config = function()
      require("tokyonight").setup({
        on_highlights = function(hightlights, colors)
          hightlights.CocInlayHint = {
            fg = "#666666",
          }
        end
      })
      vim.cmd([[
        colorscheme tokyonight-night
      ]])
    end,
  }
}
