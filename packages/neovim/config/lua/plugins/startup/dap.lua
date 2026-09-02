return {
  {
    "mfussenegger/nvim-dap",
    dependencies = { "rcarriga/nvim-dap-ui" },
    lazy = true,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    lazy = true,
  },
  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
  }
}
