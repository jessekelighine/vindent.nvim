-- plugin/vindent.lua

if vim.fn.exists("g:loaded_vindent") == 1 then vim.cmd.finish() end

if vim.fn.exists("g:vindent_count") == 0 then vim.g.vindent_count = 0 end
if vim.fn.exists("g:vindent_begin") == 0 then vim.g.vindent_begin = true end
if vim.fn.exists("g:vindent_infer") == 0 then vim.g.vindent_infer = false end
if vim.fn.exists("g:vindent_noisy") == 0 then vim.g.vindent_noisy = false end

vim.g.loaded_vindent = true
