local dap = require("dap")
local dapui = require("dapui")

dapui.setup()
-- デバッグ開始時に自動でUIを開き、終了時に閉じるリスナー
dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

-- 1. アダプタの定義 (NixOSのPATHにあるものを利用)
dap.adapters.lldb = {
	type = "executable",
	-- ※注意: 環境によっては 'lldb-vscode' の場合があるので `which` で確認すること
	command = "lldb-dap",
	name = "lldb",
}

-- 2. コンフィグレーション (C++用)
dap.configurations.cpp = {
	{
		name = "Launch",
		type = "lldb",
		request = "launch",
		-- デバッグ対象のバイナリを指定
		-- ここでは Makefile で生成される `build/` 以下の実行ファイルを想定
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {}, -- 必要なら引数を指定

		-- 外部ライブラリのソースコードにステップインした場合のパス解決（必要に応じて）
		-- env = function()
		--   local variables = {}
		--   for k, v in pairs(vim.fn.environ()) do
		--     table.insert(variables, string.format("%s=%s", k, v))
		--   end
		--   return variables
		-- end,
	},
}

-- C言語も同じ設定を使う
dap.configurations.c = dap.configurations.cpp

-- Python 用のデバッグ設定を追加
local debugpy_path = vim.fn.exepath("debugpy-adapter") 
-- Nixでインストールされる実行ファイル名に依存します。
-- 'python' にモジュールとして実行させるパターンもあります。

dap.adapters.python = function(cb, config)
  if config.request == 'attach' then
    --- ... 既存のプロセスへのアタッチ設定 (必要であれば)
  else
    cb({
      type = 'executable',
      command = vim.fn.exepath('python'), -- Nix環境のPythonバイナリ
      args = { '-m', 'debugpy.adapter' },
    })
  end
end

dap.configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = "Launch file",
    program = "${file}",
    pythonPath = function()
      -- 必要であれば仮想環境を解決するロジックをここに入れます
      return vim.fn.exepath('python')
    end,
  },
}
