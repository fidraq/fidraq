local ok, dap = pcall(require, "dap")
if not ok then
	return
end

-- dlv is pinned in mise.toml. Start nvim from the repo so mise's env
-- (DATABASE_URL, secrets from mise.local.toml, ...) reaches khazina.
dap.adapters.go = {
	type = "server",
	port = "${port}",
	executable = {
		command = "dlv",
		args = { "dap", "-l", "127.0.0.1:${port}" },
	},
}

dap.configurations.go = {
	{
		type = "go",
		name = "Debug Khazina",
		request = "launch",
		program = vim.fn.getcwd() .. "/khazina",
		cwd = vim.fn.getcwd() .. "/khazina",
	},
}

print("✅ Fidraq Debug Config Loaded (Khazina)")
