return {
	"olimorris/codecompanion.nvim",
	keys = {
		{
			"<Space>cf",
			":CodeCompanion<CR>",
			mode = { "n", "v" },
			silent = true,
		},
		{
			"<Space>cc",
			":CodeCompanionChat<CR>",
			mode = { "n", "v" },
			silent = true,
		},
		{
			"<Space>ca",
			-- 指摘: 公式のコマンド名は Actions (複数形) です。古い Action だと動かない可能性があります。
			":CodeCompanionActions<CR>", 
			mode = { "n", "v" },
			silent = true,
		},
	},

	-- config = function() は削除し、Lazy.nvim の自動 setup に任せる
	opts = {
		adapters = {
			http = { -- 修正1: http の下にネストする
				opts = {
					-- 修正4: allow_insecure はグローバルではなく http.opts の下に配置する仕様に変更されています
					allow_insecure = true,
				},
				ollama_remote = function()
					return require("codecompanion.adapters").extend("ollama", {
						name = "ollama_remote",
						env = {
							url = "https://ollama-caspar.arc.upiscium.dev",
						},
						parameters = {
							sync = true,
						},
						schema = {
							model = {
								default = "qwen3.6:27b",
							},
							num_ctx = {
								default = 16384,
							},
							num_predict = {
								default = -1,
							},
						},
					})
				end,
			},
		},
		interactions = { -- 修正2: strategies から interactions へ変更
			chat = {
				adapter = "ollama_remote",
				roles = {
					llm = function(adapter)
						return "  CodeCompanion (" .. adapter.formatted_name .. ")"
					end,
					user = "  Me",
				},
				keymaps = {
					send = {
						modes = {
							n = "<C-Enter>",
							i = "<C-Enter>",
							v = "<C-Enter>",
						},
					},
				},
			},
			inline = {
				adapter = "ollama_remote",
			},
			cmd = { -- 修正3: agent は最近のアップデートで cmd または cli という名前に整理されています
				adapter = "ollama_remote",
			},
		},
		display = {
			chat = {
				auto_scroll = false,
				show_header_separator = true,
			},
		},
		-- 修正5: 捨てられていた設定を opts のルートで正しく生かす
		language = "japanese",
		extensions = {
			mcphub = {
				callback = "mcphub.extensions.codecompanion",
				opts = {
					make_vars = true,
					make_slash_commands = true,
					show_result_in_chat = true,
				},
			},
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
	},
}
