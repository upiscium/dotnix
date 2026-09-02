return {
  { "nvim-lua/plenary.nvim" },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim",
		{
			"b0o/schemastore.nvim",
			ft = { "json", "yaml", "toml" },
		},
  } }
}
