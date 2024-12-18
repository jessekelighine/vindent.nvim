-- plugin/vindent.lua

if vim.fn.exists("g:loaded_vindent") == 1 then vim.cmd.finish() end

if vim.fn.exists("g:vindent_count") == 0 then vim.g.vindent_count = 0 end
if vim.fn.exists("g:vindent_begin") == 0 then vim.g.vindent_begin = true end
if vim.fn.exists("g:vindent_jumps") == 0 then vim.g.vindent_jumps = true end
if vim.fn.exists("g:vindent_infer") == 0 then vim.g.vindent_infer = false end
if vim.fn.exists("g:vindent_noisy") == 0 then vim.g.vindent_noisy = false end

-- Helpers --------------------------------------------------------------------

local help = { sep = "_" }

help.join = function(str1, str2)
	return str1 .. help.sep .. str2
end

help.plug_name = function(name, ending)
	return "<Plug>(Vindent" .. help.join(name, ending) .. ")"
end

help.block_symbol = function(skip, func)
	return (skip and "X" or "O") .. (func == "nole" and "X" or "O")
end

help.escape = function()
	vim.fn.execute("norm! " .. vim.api.nvim_eval('"\\<Esc>"'))
end

-- Main -----------------------------------------------------------------------

local vindent = require("vindent")

local name = "Motion"
for _, func in pairs({ "less", "diff", "more", "same" }) do
	for _, mode in pairs({ "n", "o", "x" }) do
		for _, direction in pairs({ "prev", "next" }) do
			local name_ending = help.join(func, direction)
			local plug_name = help.plug_name(name, name_ending)
			vim.keymap.set(mode, plug_name, function()
				local count = vim.v.count1
				help.escape()
				vindent[name](direction, true, func, mode, count)
			end)
		end
	end
end

local name = "BlockMotion"
for _, func in pairs({ "same", "nole" }) do
	for _, skip in pairs({ true, false }) do
		for _, mode in pairs({ "n", "o", "x" }) do
			for _, direction in pairs({ "prev", "next" }) do
				local block_symbol = help.block_symbol(skip, func)
				local name_ending = help.join(block_symbol, direction)
				local plug_name = help.plug_name(name, name_ending)
				vim.keymap.set(mode, plug_name, function()
					local count = vim.v.count1
					help.escape()
					vindent[name](direction, skip, func, mode, count)
				end)
			end
		end
	end
end

local name = "BlockEdgeMotion"
for _, func in pairs({ "same", "nole" }) do
	for _, skip in pairs({ true, false }) do
		for _, mode in pairs({ "n", "o", "x" }) do
			for _, direction in pairs({ "prev", "next" }) do
				local block_symbol = help.block_symbol(skip, func)
				local name_ending = help.join(block_symbol, direction)
				local plug_name = help.plug_name(name, name_ending)
				vim.keymap.set(mode, plug_name, function()
					help.escape()
					vindent[name](direction, skip, func, mode)
				end)
			end
		end
	end
end

local name = "Object"
for _, func in pairs({ "same", "nole" }) do
	for _, code in pairs({ "ii", "ai", "aI" }) do
		for _, skip in pairs({ true, false }) do
			for _, mode in pairs({ "o", "x" }) do
				local block_symbol = help.block_symbol(skip, func)
				local name_ending = help.join(block_symbol, code)
				local plug_name = help.plug_name(name, name_ending)
				vim.keymap.set(mode, plug_name, function()
					local count = vim.g.vindent_count == 1 and vim.v.count1 or vim.v.count
					help.escape()
					vindent[name](skip, func, code, count)
				end)
			end
		end
	end
end

vim.g.loaded_vindent = true
