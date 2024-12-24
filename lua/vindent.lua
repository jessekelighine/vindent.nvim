-- lua/vindent.lua

local is_empty = function(line)
	return vim.fn.empty(vim.fn.getline(line)) == 1
end

local is_valid = function(line)
	return line >= 1 and line <= vim.fn.line("$")
end

local do_escape = function()
	vim.fn.execute("norm! " .. vim.api.nvim_eval('"\\<Esc>"'))
end

-- Indentation Handling -------------------------------------------------------

local compare = {
	same = function(x, y) return x == y end,
	nole = function(x, y) return x >= y end,
	less = function(x, y) return x < y end,
	more = function(x, y) return x > y end,
	diff = function(x, y) return x ~= y end,
}

local get_indent = function(line)
	return is_empty(line) and -1 or vim.fn.indent(line)
end

local infer_indent = function(line, infer)
	infer = infer or vim.g.vindent_infer
	if not infer or not is_empty(line) then
		return get_indent(line)
	end
	local line_prev = vim.fn.prevnonblank(line)
	local line_next = vim.fn.nextnonblank(line)
	local indent_prev = is_valid(line_prev) and get_indent(line_prev) or 0
	local indent_next = is_valid(line_next) and get_indent(line_next) or 0
	local indent = vim.fn.max({ indent_prev, indent_next })
	return indent == 0 and -1 or indent
end

-- Main Logic -----------------------------------------------------------------

local find_til = function(direction, func, skip, start, base)
	base = base or start
	local base_indent = infer_indent(base)
	local line = start
	local step = direction == "next" and 1 or -1
	while true do
		line = line + step
		if not is_valid(line) then return start end
		if skip and is_empty(line) then goto continue end
		if compare[func](get_indent(line), base_indent) then
			return line
		end
		::continue::
	end
end

local find_til_not = function(direction, func, skip, start, base)
	base = base or start
	local base_indent = infer_indent(base)
	local line = start
	local step = direction == "next" and 1 or -1
	while true do
		line = line + step
		if not is_valid(line) then return line - step end
		if skip and is_empty(line) then goto continue end
		if not compare[func](get_indent(line), base_indent) then
			return line - step
		end
		::continue::
	end
end

local do_motion = function(direction, mode, diff)
	local mark = vim.g.vindent_jumps and "m'" or ""
	local move = diff .. (direction == "next" and "j" or "k")
	local escape = vim.api.nvim_eval('"\\<Esc>"')
	local finish = vim.g.vindent_begin and "_" or ""
	if diff == 0 then
		local command = {
			n = "norm!" .. "lh" .. finish,
			x = "norm!" .. "gv",
			o = "norm!" .. "V",
		}
		vim.fn.execute(command[mode])
	else
		local command = {
			n = "norm!" .. mark .. move .. finish,
			x = "norm!" .. escape .. mark .. "gv" .. move .. finish,
			o = "norm!" .. mark .. "V" .. move .. finish,
		}
		vim.fn.execute(command[mode])
	end
end

local do_object = function(range)
	local diff = range[2] - range[1]
	local move = diff == 0 and "" or diff .. "j"
	local command = "norm!" .. (range[1] .. "G") .. "V" .. move
	vim.fn.execute(command)
end

-- Motions and Objects --------------------------------------------------------

local Motion = function(direction, skip, func, mode, count)
	local line = vim.fn.line(".")
	local to = vim.fn.line(".")
	for _ = 1, count do
		to = find_til(direction, func, skip, to)
	end
	if vim.g.vindent_noisy and line == to then
		local error_message = "Motion Not Applicable"
		vim.api.nvim_err_writeln(error_message)
	end
	do_motion(direction, mode, vim.fn.abs(line - to))
end

local BlockMotion = function(direction, skip, func, mode, count)
	local line = vim.fn.line(".")
	local to = vim.fn.line(".")
	for _ = 1, count do
		local edge = find_til_not(direction, func, skip, to)
		to = find_til(direction, "same", skip, edge, to)
	end
	if vim.g.vindent_noisy and line == to then
		local error_message = "Block Motion Not Applicable"
		vim.api.nvim_err_writeln(error_message)
	end
	do_motion(direction, mode, vim.fn.abs(line - to))
end

local BlockEdgeMotion = function(direction, skip, func, mode)
	local line = vim.fn.line(".")
	local edge = find_til_not(direction, func, skip, line)
	if direction == "next" then
		edge = vim.fn.prevnonblank(edge)
	else
		edge = vim.fn.nextnonblank(edge)
	end
	do_motion(direction, mode, vim.fn.abs(line - edge))
end

local Object = function(skip, func, code, count)
	local get_full_range = function(range)
		return {
			find_til_not("prev", func, skip, range[1]),
			find_til_not("next", func, skip, range[2]),
		}
	end

	local get_range = function(full_range)
		return {
			vim.fn.nextnonblank(full_range[1]),
			vim.fn.prevnonblank(full_range[2]),
		}
	end

	local get_range_candidate = function(new_line, base_line)
		local new_indent = get_indent(new_line)
		local base_indent = get_indent(base_line)
		local less_indent = compare.less(new_indent, base_indent)
		local valid = is_valid(new_line)
		local not_empty = not is_empty(new_line)
		return (less_indent and valid and not_empty) and new_line or base_line
	end

	local line = vim.fn.line(".")
	local full_range = get_full_range({ line, line })
	local range = get_range(full_range)

	local repetition = count - vim.g.vindent_count
	for _ = 1, repetition do
		local test_range = {
			get_range_candidate(full_range[1] - 1, range[1]),
			get_range_candidate(full_range[2] + 1, range[2]),
		}
		if test_range[1] ~= range[1] and test_range[2] ~= range[2] then
			local test_indent1 = get_indent(test_range[1])
			local test_indent2 = get_indent(test_range[2])
			if compare.more(test_indent1, test_indent2) then
				test_range[2] = range[2]
			elseif compare.less(test_indent1, test_indent2) then
				test_range[1] = range[1]
			end
		end
		full_range = get_full_range(test_range)
		range = get_range(full_range)
	end

	if string.sub(code, 1, 1) == "a" then range[1] = find_til("prev", "less", true, range[1]) end
	if string.sub(code, 2, 2) == "I" then range[2] = find_til("next", "less", true, range[2]) end
	do_object(range)
end

-- Interface ------------------------------------------------------------------

local M = { map = {} }

---@class opts.Blockwise
---@field skip_empty_lines boolean: whether to skip "empty lines" when searching for text block boundaries
---@field skip_more_indented_lines boolean: whether to skip "more-indented lines" when searching for text block boundaries

---@param opts opts.Blockwise: blockwise motion/object options
local blockwise_opts_code = function(opts)
	local code1 = opts.skip_empty_lines and "X" or "O"
	local code2 = opts.skip_more_indented_lines and "X" or "O"
	return "(blockwise opts: " .. code1 .. code2 .. ")"
end

---@param key_sequences string[]: a table with keys `prev` and `next` to define key bindings
---@param motion_type string: `same`, `less`, `more`, or `diff` to indicate motion type
M.map.Motion = function(key_sequences, motion_type)
	for _, mode in pairs({ "n", "o", "x" }) do
		for direction, key_sequence in pairs(key_sequences) do
			local desc = "Vindent Motion: " .. motion_type .. " " .. direction
			vim.keymap.set(mode, key_sequence,
				function()
					local count = vim.v.count1
					do_escape()
					Motion(direction, true, motion_type, mode, count)
				end,
				{ desc = desc }
			)
		end
	end
end

---@param key_sequences string[]: a table with keys `prev` and `next` to define key bindings
---@param opts opts.Blockwise: blockwise motion/object options
M.map.BlockMotion = function(key_sequences, opts)
	local func = opts.skip_more_indented_lines and "nole" or "same"
	for _, mode in pairs({ "n", "o", "x" }) do
		for direction, key_sequence in pairs(key_sequences) do
			local desc = "Vindent BlockMotion: " .. blockwise_opts_code(opts) .. " " .. direction
			vim.keymap.set(mode, key_sequence,
				function()
					local count = vim.v.count1
					do_escape()
					BlockMotion(direction, opts.skip_empty_lines, func, mode, count)
				end,
				{ desc = desc }
			)
		end
	end
end

---@param key_sequences string[]: a table with keys `prev` and `next` to define key bindings
---@param opts opts.Blockwise: blockwise motion/object options
M.map.BlockEdgeMotion = function(key_sequences, opts)
	local func = opts.skip_more_indented_lines and "nole" or "same"
	for _, mode in pairs({ "n", "o", "x" }) do
		for direction, key_sequence in pairs(key_sequences) do
			local desc = "Vindent BlockEdgeMotion: " .. blockwise_opts_code(opts) .. " " .. direction
			vim.keymap.set(mode, key_sequence,
				function()
					do_escape()
					BlockEdgeMotion(direction, opts.skip_empty_lines, func, mode)
				end,
				{ desc = desc }
			)
		end
	end
end

---@param key_sequence string: left-hand side of mapping, key sequence
---@param object_type string: `ii` `ai`, or `aI` to indicate type of object
---@param opts opts.Blockwise: blockwise motion/object options
M.map.Object = function(key_sequence, object_type, opts)
	local func = opts.skip_more_indented_lines and "nole" or "same"
	for _, mode in pairs({ "o", "x" }) do
		local desc = "Vindent Object: " .. blockwise_opts_code(opts) .. " " .. object_type
		vim.keymap.set(mode, key_sequence,
			function()
				local count = vim.g.vindent_count == 1 and vim.v.count1 or vim.v.count
				do_escape()
				Object(opts.skip_empty_lines, func, object_type, count)
			end,
			{ desc = desc }
		)
	end
end

return M
