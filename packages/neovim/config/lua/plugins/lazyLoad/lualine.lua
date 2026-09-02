return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-web-devicons", opt = true },
	event = { "BufNewFile", "BufRead" },
	config = function()
		local spinner = require("config.cc-component").cc_spinner()
		require("lualine").setup({
			options = {
				theme = "tokyonight",
			},
			sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {spinner},
				lualine_x = { { "filename", path = 3 } },
				lualine_y = { "encoding", "fileformat" },
				lualine_z = {},
			},
		})
	end,
}
