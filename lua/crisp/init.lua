local M = {}

function M.setup()
	vim.api.nvim_create_user_command("Command", function()
		print("Hello from setup")
	end, {})
end

return M
