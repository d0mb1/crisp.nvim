local M = {}

function M.show_files()
	local buf = vim.api.nvim_create_buf(false, true)
	local lines = vim.tbl_map(function(line)
		return line:gsub("\n", "")
	end, vim.fn.systemlist("ls -la"))
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_name(buf, "crisp-files")

	vim.keymap.set("n", "q", function()
		vim.api.nvim_buf_delete(buf, { force = true })
	end, { buffer = buf })

	vim.keymap.set("n", "<CR>", function()
		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
		local line = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1]
		local filename = line:match("^%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(%S+)")
		if filename then
			vim.api.nvim_buf_delete(buf, { force = true })
			vim.cmd.edit(filename)
		end
	end, { buffer = buf })

	local width = math.max(80, vim.o.columns - 10)
	local height = math.max(20, vim.o.lines - 5)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})
end

vim.api.nvim_create_user_command("CrispFiles", M.show_files, {})

return M
