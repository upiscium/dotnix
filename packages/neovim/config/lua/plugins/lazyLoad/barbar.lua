return {
	"romgrk/barbar.nvim",
	config = function()
		require("barbar").setup({
			event = "BufRead",
			animation = false,
			auto_hide = false,
			tabpages = true,
			icons = {
				buffer_index = false,
				buffer_number = false,
				button = "x",
				diagnostics = {
					[vim.diagnostic.severity.ERROR] = { enabled = true, icon = "" },
					[vim.diagnostic.severity.WARN] = { enabled = false },
					[vim.diagnostic.severity.INFO] = { enabled = false },
					[vim.diagnostic.severity.HINT] = { enabled = true },
				},
				gitsigns = {
					added = { enabled = true, icon = "" },
					changed = { enabled = true, icon = "" },
					deleted = { enabled = true, icon = "" },
				},
				filetype = {
					custom_colors = false,
					enabled = true,
				},
				preset = "default",
			},
		})
	end,
}
