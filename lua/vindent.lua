-- lua/vindent.lua

---@class BlockOpts
---@field skip_empty_lines boolean: whether to skip "empty lines" when searching for text block boundaries
---@field skip_more_indented_lines boolean: whether to skip "more-indented lines" when searching for text block boundaries

-- Helper Functions -----------------------------------------------------------

local helper = {}

-- escape to normal mode
helper.escape = function()
	vim.fn.execute("norm! " .. vim.api.nvim_eval('"\\<Esc>"'))
end

---@param opts BlockOpts: block-wise motion/object options (table)
---@return string: `func` that corresponds to `BlockOpts`
helper.block_opts_func = function(opts)
	return opts.skip_more_indented_lines and "nole" or "same"
end

---@param opts BlockOpts: block-wise motion/object options (table)
---@return string: description code for `BlockOpts`
helper.block_opts_code = function(opts)
	local code1 = opts.skip_empty_lines and "X" or "O"
	local code2 = opts.skip_more_indented_lines and "X" or "O"
	return "(BlockOpts: " .. code1 .. code2 .. ")"
end

---@param name string: `"Motion"`, `"BlockMotion"`, `"BlockEdgeMotion"`, or `"Object"`
---@param middle string|BlockOpts: middle part to put in description 
---@param ending string: either `direction` or `motion_type`
---@return string: description of mapping
helper.desc = function(name, middle, ending)
	name = "Vindent " .. name .. ":"
	if type(middle) ~= "string" then middle = helper.block_opts_code(middle) end
	return name .. " " .. middle .. " " .. ending
end

-- Interface ------------------------------------------------------------------

local M = { map = {} }

local vindent = require("vindent-core")

---@param opts table: table with fields `"begin"`, `"jumps"`, `"noisy"` or `"infer"`, corresponding to the global settings
M.setup = function(opts)
	if opts.begin ~= nil then vim.g.vindent_begin = opts.begin end
	if opts.jumps ~= nil then vim.g.vindent_jumps = opts.jumps end
	if opts.noisy ~= nil then vim.g.vindent_noisy = opts.noisy end
	if opts.infer ~= nil then vim.g.vindent_infer = opts.infer end
end

---@param key_sequences table: a table with fields `"prev"` and `"next"` to define key bindings
---@param motion_type string: `"same"`, `"less"`, `"more"`, or `"diff"` to indicate motion type
M.map.Motion = function(key_sequences, motion_type)
	local name = "Motion"
	for direction, key_sequence in pairs(key_sequences) do
		local desc = helper.desc(name, motion_type, direction)
		for _, mode in pairs({ "n", "o", "x" }) do
			vim.keymap.set(mode, key_sequence, function()
				local count = vim.v.count1
				helper.escape()
				vindent[name](direction, true, motion_type, mode, count)
			end, { desc = desc })
		end
	end
end

---@param key_sequences table: a table with fields `"prev"` and `"next"` to define key bindings
---@param opts BlockOpts: block-wise motion/object options (table)
M.map.BlockMotion = function(key_sequences, opts)
	local name = "BlockMotion"
	local func = helper.block_opts_func(opts)
	for direction, key_sequence in pairs(key_sequences) do
		local desc = helper.desc(name, opts, direction)
		for _, mode in pairs({ "n", "o", "x" }) do
			vim.keymap.set(mode, key_sequence, function()
				local count = vim.v.count1
				helper.escape()
				vindent[name](direction, opts.skip_empty_lines, func, mode, count)
			end, { desc = desc })
		end
	end
end

---@param key_sequences table: a table with fields `"prev"` and `"next"` to define key bindings
---@param opts BlockOpts: block-wise motion/object options (table)
M.map.BlockEdgeMotion = function(key_sequences, opts)
	local name = "BlockEdgeMotion"
	local func = helper.block_opts_func(opts)
	for direction, key_sequence in pairs(key_sequences) do
		local desc = helper.desc(name, opts, direction)
		for _, mode in pairs({ "n", "o", "x" }) do
			vim.keymap.set(mode, key_sequence, function()
				helper.escape()
				vindent[name](direction, opts.skip_empty_lines, func, mode)
			end, { desc = desc })
		end
	end
end

---@param key_sequence string: left-hand side of mapping, key sequence
---@param object_type string: `"ii"` `"ai"`, or `"aI"` to indicate type of object
---@param opts BlockOpts: block-wise motion/object options (table)
M.map.Object = function(key_sequence, object_type, opts)
	local name = "Object"
	local func = helper.block_opts_func(opts)
	local desc = helper.desc(name, opts, object_type)
	for _, mode in pairs({ "o", "x" }) do
		vim.keymap.set(mode, key_sequence, function()
			local count = vim.g.vindent_count == 1 and vim.v.count1 or vim.v.count
			helper.escape()
			vindent[name](opts.skip_empty_lines, func, object_type, count)
		end, { desc = desc })
	end
end

return M
