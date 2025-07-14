-- lua/vindent-core.lua

local empty = function(line)
	return vim.fn.empty(vim.fn.getline(line)) == 1
end

local valid = function(line)
	return line >= 1 and line <= vim.fn.line("$")
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
	return empty(line) and -1 or vim.fn.indent(line)
end

local infer_indent = function(line, infer)
	infer = infer or vim.g.vindent_infer
	if not infer or not empty(line) then
		return get_indent(line)
	end
	local line_prev = vim.fn.prevnonblank(line)
	local line_next = vim.fn.nextnonblank(line)
	local indent_prev = valid(line_prev) and get_indent(line_prev) or 0
	local indent_next = valid(line_next) and get_indent(line_next) or 0
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
		if not valid(line) then return start end
		if skip and empty(line) then goto continue end
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
		if not valid(line) then return line - step end
		if skip and empty(line) then goto continue end
		if not compare[func](get_indent(line), base_indent) then
			return line - step
		end
		::continue::
	end
end

local do_motion = function(mode, from, to)
	local mark = vim.g.vindent_jumps and "m'" or ""
	local move = to .. "G"
	local escape = vim.api.nvim_eval('"\\<Esc>"')
	local finish = vim.g.vindent_begin and "_" or ""
	if from == to then
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
	local command = "norm!" .. (range[1] .. "G") .. "V" .. (range[2] .. "G")
	vim.fn.execute(command)
end

-- Motions and Objects --------------------------------------------------------

local M = {}

M.Motion = function(direction, skip, func, mode, count)
	local line = vim.fn.line(".")
	local to = vim.fn.line(".")
	for _ = 1, count do
		to = find_til(direction, func, skip, to)
	end
	if vim.g.vindent_noisy and line == to then
		local error_message = "Error: Motion Not Applicable"
		vim.api.nvim_echo({{ error_message }}, true, { err = true })
	end
	do_motion(mode, line, to)
end

M.BlockMotion = function(direction, skip, func, mode, count)
	local line = vim.fn.line(".")
	local to = vim.fn.line(".")
	for _ = 1, count do
		local edge = find_til_not(direction, func, skip, to)
		to = find_til(direction, "same", skip, edge, to)
	end
	if vim.g.vindent_noisy and line == to then
		local error_message = "Error: Block Motion Not Applicable"
		vim.api.nvim_echo({{ error_message }}, true, { err = true })
	end
	do_motion(mode, line, to)
end

M.BlockEdgeMotion = function(direction, skip, func, mode)
	local line = vim.fn.line(".")
	local edge = find_til_not(direction, func, skip, line)
	if direction == "next" then
		edge = vim.fn.prevnonblank(edge)
	else
		edge = vim.fn.nextnonblank(edge)
	end
	if vim.g.vindent_noisy and line == edge then
		local error_message = "Error: Block Edge Motion Not Applicable"
		vim.api.nvim_echo({{ error_message }}, true, { err = true })
	end
	do_motion(mode, line, edge)
end

M.Object = function(skip, func, code, count)
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
		local is_valid = valid(new_line)
		local not_empty = not empty(new_line)
		return (less_indent and is_valid and not_empty) and new_line or base_line
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

return M
