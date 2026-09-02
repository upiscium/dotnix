return {
	"ravitemer/mcphub.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
	},
	-- comment the following line to ensure hub will be ready at the earliest
	cmd = "MCPHub", -- lazy load by default
	build = "bundled_build.lua",
	config = function()
		local configs = vim.api.nvim_get_runtime_file("mcphub/servers.json", false)
		local config = configs[1]
		if not config then
			error("packaged MCPHub config not found on runtimepath")
		end

		require("mcphub").setup({
			auto_approve = false,
			use_bundled_binary = true,
			config = config,
		})
	end,
}
