local M = {}

-- State to track our managed windows and their paths
local state = {
	columns = {}, -- List of { winid = number, bufnr = number, path = string }
}

-- Utility to get files in a directory
local function get_files(path)
	local files = {}
	local handle = vim.loop.fs_scandir(path)
	if not handle then
		return files
	end

	while true do
		local name, type = vim.loop.fs_scandir_next(handle)
		if not name then
			break
		end
		table.insert(files, name .. (type == "directory" and "/" or ""))
	end
	return files
end

-- Create or update a buffer for a specific path
local function create_dir_buffer(path)
	local buf = vim.api.nvim_create_buf(false, true)
	local files = get_files(path)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, files)
	vim.api.nvim_buf_set_name(buf, "multioil://" .. path)
	vim.api.nvim_set_option_value("filetype", "multioil", { buf = buf })
	vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })

	-- The Magic: Syncing back to disk
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			M.sync_to_disk(buf, path)
		end,
	})

	return buf
end

-- Synchronize buffer lines to the actual filesystem
function M.sync_to_disk(buf, path)
	local old_files = get_files(path)
	local new_files = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	-- Simplified logic: Rename or delete
	-- In a production plugin, you'd diff old_files and new_files
	print("Syncing " .. path .. "...")
	vim.api.nvim_buf_set_modified(buf, false)
end

-- Render the multi-column view
function M.open(target_path)
	target_path = vim.fn.fnamemodify(target_path, ":p")

	-- Clear existing columns for simplicity in this MVP
	vim.cmd("only")

	-- Example: Show Parent | Current
	local parent = vim.fn.fnamemodify(target_path, ":h:h") .. "/"
	local current = target_path

	local paths = { parent, current }

	for i, path in ipairs(paths) do
		if i > 1 then
			vim.cmd("vsplit")
		end
		local buf = create_dir_buffer(path)
		vim.api.nvim_set_current_buf(buf)

		-- Basic keymaps
		vim.keymap.set("n", "<CR>", function()
			local line = vim.api.nvim_get_current_line()
			local next_path = path .. line
			if next_path:sub(-1) == "/" then
				M.open(next_path)
			else
				vim.cmd("edit " .. vim.fn.fnameescape(next_path))
			end
		end, { buffer = buf })
	end
end

-- Setup function to hijack netrw
function M.setup()
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			local stats = vim.loop.fs_stat(vim.fn.expand("%:p"))
			if stats and stats.type == "directory" then
				M.open(vim.fn.expand("%:p"))
			end
		end,
	})

	-- Disable netrw
	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1
end

return M
