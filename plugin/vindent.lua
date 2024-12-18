-- plugin/vindent.lua

if vim.fn.exists("g:loaded_vindent") == 1 then vim.cmd.finish() end

if vim.fn.exists("g:vindent_count") == 0 then vim.g.vindent_count = 0 end
if vim.fn.exists("g:vindent_begin") == 0 then vim.g.vindent_begin = true end
if vim.fn.exists("g:vindent_jumps") == 0 then vim.g.vindent_jumps = true end
if vim.fn.exists("g:vindent_infer") == 0 then vim.g.vindent_infer = false end
if vim.fn.exists("g:vindent_noisy") == 0 then vim.g.vindent_noisy = false end

local vindent = require("vindent")

local name = "Motion"
for _, func in pairs({ "less", "diff", "more", "same" }) do
	for _, mode in pairs({ "n", "o", "x" }) do
		for _, direction in pairs({ "prev", "next" }) do
			local name_ending = func .. "_" .. direction
			local plug_name = "<Plug>(Vindent" .. name .. "_" .. name_ending .. ")"
			vim.keymap.set(mode, plug_name, function()
				local count = vim.v.count1
				vim.fn.execute("norm! " .. vim.api.nvim_eval('"\\<Esc>"'))
				vindent[name](direction, true, func, mode, count)
			end)
		end
	end
end

-- @diagnostics-off
local name = "BlockMotion"
for _, func in pairs({ "same", "nole" }) do
	for _, skip in pairs({ true, false }) do
		for _, mode in pairs({ "n", "o", "x" }) do
			for _, direction in pairs({ "prev", "next" }) do
				local skip_symbol = skip and "X" or "O"
				local func_symbol = func == "nole" and "X" or "O"
				local name_ending = skip_symbol .. func_symbol .. "_" .. direction
				local plug_name = "<Plug>(Vindent" .. name .. "_" .. name_ending .. ")"
				vim.keymap.set(mode, plug_name, function()
					local count = vim.v.count1
					vim.fn.execute("norm! " .. vim.api.nvim_eval('"\\<Esc>"'))
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
				local skip_symbol = skip and "X" or "O"
				local func_symbol = func == "nole" and "X" or "O"
				local name_ending = skip_symbol .. func_symbol .. "_" .. direction
				local plug_name = "<Plug>(Vindent" .. name .. "_" .. name_ending .. ")"
				vim.keymap.set(mode, plug_name, function()
					vim.fn.execute("norm! " .. vim.api.nvim_eval('"\\<Esc>"'))
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
				local skip_symbol = skip and "X" or "O"
				local func_symbol = func == "nole" and "X" or "O"
				local name_ending = skip_symbol .. func_symbol .. "_" .. code
				local plug_name = "<Plug>(Vindent" .. name .. "_" .. name_ending .. ")"
				vim.keymap.set(mode, plug_name, function()
					local count = vim.g.vindent_count == 1 and vim.v.count1 or vim.v.count
					vim.fn.execute("norm! " .. vim.api.nvim_eval('"\\<Esc>"'))
					vindent[name](skip, func, code, count)
				end)
			end
		end
	end
end

vim.g.loaded_vindent = true
