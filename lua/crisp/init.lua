local M = {}

M.state = {
	root = nil,
	wins = {},
	focused_idx = 1,
	entries = {},
}

function M.setup()
	vim.api.nvim_create_user_command("Crack", function()
		M.open(vim.fn.expand("%:p:h"))
	end, {})
end

function M.setup_keymaps(win)
	local buf = vim.api.nvim_win_get_buf(win)
	vim.keymap.set("n", "j", function()
		if M.state.focused_idx < #M.state.entries then
			M.state.focused_idx = M.state.focused_idx + 1
			M.update_views()
		end
	end, { buffer = buf })

	vim.keymap.set("n", "k", function()
		if M.state.focused_idx > 1 then
			M.state.focused_idx = M.state.focused_idx - 1
			M.update_views()
		end
	end, { buffer = buf })

	vim.keymap.set("n", "<CR>", function()
		local entry = M.state.entries[M.state.focused_idx]
		if entry and entry.is_dir then
			M.open(entry.path)
		end
	end, { buffer = buf })

	vim.keymap.set("n", "q", function()
		vim.cmd("tabclose")
	end, { buffer = buf })
end

function M.open(path)
	path = vim.fn.fnamemodify(path, ":p")
	M.state.root = path
	M.state.entries = M.read_dir(path)
	M.state.focused_idx = 1
	M.create_windows()
	M.update_views()
end

function M.read_dir(path)
	local entries = {}
	local handle = vim.uv.fs_scandir(path)
	if handle then
		while true do
			local name = vim.uv.fs_scandir_next(handle)
			if not name then
				break
			end
			local full_path = path .. name
			local stat = vim.uv.fs_stat(full_path)
			table.insert(entries, {
				name = name,
				path = full_path,
				is_dir = stat and stat.type == "directory",
			})
		end
	end
	return entries
end

function M.create_windows()
	vim.cmd("tabedit")
	vim.cmd("leftabove vsplit")
	vim.cmd("rightbelow vsplit")

	local tabnr = vim.api.nvim_get_current_tabpage()
	local wins = vim.api.nvim_tabpage_list_wins(tabnr)
	M.state.wins = {
		left = wins[1],
		center = wins[2],
		right = wins[3],
	}
	M.setup_keymaps(wins[2])
end

function M.update_views()
	local entries = M.state.entries
	local idx = M.state.focused_idx

	M.render_center(entries, idx)
	M.render_left(entries, idx)
	M.render_right(entries[idx])

	vim.api.nvim_set_current_win(M.state.wins.center)
end

function M.render_center(entries, idx)
	local buf = vim.api.nvim_create_buf(false, true)
	local lines = {}
	for i, entry in ipairs(entries) do
		local icon = entry.is_dir and "[d]" or "[f]"
		local prefix = i == idx and "> " or "  "
		table.insert(lines, prefix .. icon .. " " .. entry.name)
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_win_set_buf(M.state.wins.center, buf)

	vim.api.nvim_set_option_value("number", true, { win = M.state.wins.center })
	local ns = vim.api.nvim_create_namespace("crisp")
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	if entries[idx] then
		vim.api.nvim_buf_add_highlight(buf, ns, "Visual", idx - 1, 0, -1)
	end
end

function M.render_left(entries, idx)
	local buf = vim.api.nvim_create_buf(false, true)
	if idx > 1 then
		local prev = entries[idx - 1]
		if prev.is_dir then
			local sub_entries = M.read_dir(prev.path)
			local lines = vim.tbl_map(function(e)
				return (e.is_dir and "d" or "f") .. " " .. e.name
			end, sub_entries)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		else
			local lines = M.read_file(prev.path)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		end
	end
	vim.api.nvim_win_set_buf(M.state.wins.left, buf)
end

function M.render_right(entry)
	local buf = vim.api.nvim_create_buf(false, true)
	if entry and entry.is_dir then
		local sub_entries = M.read_dir(entry.path)
		local lines = vim.tbl_map(function(e)
			return (e.is_dir and "d" or "f") .. " " .. e.name
		end, sub_entries)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	else
		local lines = M.read_file(entry.path)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end
	vim.api.nvim_win_set_buf(M.state.wins.right, buf)
end

function M.read_file(path)
	local f = io.open(path, "r")
	if not f then
		return {}
	end
	local lines = {}
	for line in f:lines() do
		table.insert(lines, line)
	end
	f:close()
	return lines
end

return M
