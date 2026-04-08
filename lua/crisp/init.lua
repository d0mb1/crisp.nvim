local M = {}

function M.setup()
	vim.api.nvim_create_user_command("Crack", function()
		print("Crack!")
	end, {})
end

return M
