# vindent.nvim

[`vindent.nvim`](https://github.com/jessekelighine/vindent.nvim)
is Neovim plugin that provides indentation related *motions* and *text objects*:

1. **Motions**: jump to specific positions defined by indentations.
	- Jump to previous/next line with *same*, *less*, *more*, or *different* indentation.
	- Jump to previous/next text block with *same* indentation.
	- Jump to start/end of the current text block of same indentation.
2. **Text Objects**: selects specific lines defined by indentations.
	- Select a text block of *same* (or specified level of) indentation.
	- Select text block plus a previous line with less indentation.
	- Select text block plus a previous and a next line with less indentation.

> **NOTE**: This plugin is the Lua version of
> [vindent.vim](https://github.com/jessekelighine/vindent.vim), which was
> written in Vimscript. The two plugins are practically the same, with minor
> differences in configuration and default settings. I find it a bit easier to
> deal with edge cases in Lua, thus why this plugin is created.

## Installation and Quick Start

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
	"jessekelighine/vindent.nvim",
	config = function()
		local vindent = require("vindent")
		local block_opts = {
			strict     = { skip_empty_lines = false, skip_more_indented_lines = false },
			contiguous = { skip_empty_lines = false, skip_more_indented_lines = true  },
			loose      = { skip_empty_lines = true,  skip_more_indented_lines = true  },
		}
		vindent.map.BlockMotion({ prev = "[=", next = "]=" }, block_opts.strict)
		vindent.map.Motion({ prev = "[-", next = "]-" }, "less")
		vindent.map.Motion({ prev = "[+", next = "]+" }, "more")
		vindent.map.Motion({ prev = "[;", next = "];" }, "diff")
		vindent.map.BlockEdgeMotion({ prev = "[p", next = "]p" }, block_opts.loose)
		vindent.map.BlockEdgeMotion({ prev = "[P", next = "]P" }, block_opts.contiguous)
		vindent.map.Object("iI", "ii", block_opts.strict)
		vindent.map.Object("ii", "ii", block_opts.loose)
		vindent.map.Object("ai", "ai", block_opts.loose)
		vindent.map.Object("aI", "aI", block_opts.loose)
		vindent.setup { begin = false }
	end
},
```

With these keybindings, you can now...

1. **Vindent Motions**:
	- Jump to previous/next block with same indentation with `[=`/`]=`. ([examples](#block-wise-motions))
	- Jump to previous/next line with less indentation with `[-`/`]-`. ([examples](#line-wise-motions))
	- Jump to previous/next line with more indentation with `[+`/`]+`. ([examples](#line-wise-motions))
	- Jump to previous/next line with different indentation with `[;`/`];`. ([examples](#line-wise-motions))
	- Jump to start/end of text block with `[p`/`]p` or `[P`/`]P`. ([examples](#block-wise-motions))
2. **Vindent Text Objects**: Select text block with `ii`/`iI` (*in indent*),`ai`
   (*an indent*), and `aI` (*an Indent*). ([examples](#text-objects))

## Usage

In this section, we will assume that the keybindings defined in
[quick start](#installation-and-quick-start) are used for all the examples.

### Line-wise Motions

These motions are self-explanatory: move to the previous or next line with
*same*, *less*, *more*, or *different* indentation.
These are defined with function `Motion`.

#### Line-wise Motions: Examples

```python
 1 def SumTo():
 2     print("Hello, what do you want to sum?")
 3     count = int(input("integer:"))
 4
 5     total = 0
 6     for i in range(count+1):
 7         total += i
 8
 9     print(f"This is your total: {total}")
10     return(total)
```

- If cursor is on line 3, `[-` moves it to line 1.
- If cursor is on line 7, `2[-` moves it to line 1.
- If cursor is on line 10, `[+` moves it to line 7.
- If cursor is on line 1, `2]+` moves it to line 7.

### Block-wise Motions

`vindent.nvim` provides two types of text objects:

| Motion            | Description                                         |
| :---              | :---                                                |
| `BlockMotion`     | move to the previous/next text block of same indent |
| `BlockEdgeMotion` | move to the beginning/end of current text block     |

All motions and objects that operates *block-wise* need to be told how a text block should be defined.
In particular, they need to be told what kind of lines are considered "boundaries" of a text block.
This is done by a table (class `BlockOpts`), passed to functions `BlockMotion`, `BlockEdgeMotion`, and `Object`,
with two boolean values: `skip_empty_lines` and `skip_more_indented_lines`.
Tables `strict`, `contiguous`, and `loose` defined in [quick start](#installation-and-quick-start) are examples of `BlockOpts`.
See example below.

#### Block-wise Motions: Examples

```lua
 1 local SumTo = function(number)
 2     local sum = 0
 3     for time = 1, number do
 4         print("This is the " .. time .. "-th time.")
 5         sum = sum + time
 6     end
 7
 8     print("The sum is " .. sum)
 9     return sum
10 end
```

If the cursor is on line 2, then pressing `]=` 2 times moves the cursor to line
6 and 8. This is because `strict` is used for `]=`, meaning that "empty lines"
and "more-indented lines" are all considered to be boundaries of a text block
(*not* skipped). So lines 2-3 is one block, line 6 is itself a block, and lines
8-9 is the third block.

If the cursor is on line 2, then pressing `]p` moves the cursor to line 9. This
is because `loose` is used for `]p`, meaning that "empty lines" and
"more-indented lines" are all skipped (*not* boundaries), thus line 2 to line 9
is considered to be one text block.

If the cursor is on line 2, then pressing `]P` moves the cursor to line 6. This
is because `contiguous` is used for `]P`, meaning that "more-indented lines"
are skipped but "empty lines" are not, thus line 2 to line 6 is considered to
be one text block.

### Text Objects

`vindent.nvim` provides three types of text objects:

| Text Object | Mnemonics   | Description                                                                  |
| :---        | :---        | :---                                                                         |
| `ii`        | *in indent* | select block of same indent                                                  |
| `ai`        | *an indent* | select block of same indent plus a previous line with less indent            |
| `aI`        | *an Indent* | select block of same indent plus a previous and a next line with less indent |

And object is defined with function `Object`.
Object `ai` is useful for selecting something like a Python function, and `aI`
is useful for selecting something like a Lua function. As detailed in
[block-wise motions](#block-wise-motions), you can change what is
considered to be a *text block* by setting the values in `BlockOpts` table.
Also, all text objects can take `[count]`, which makes the text objects select
`[count]` additional indent levels around. See the example below.

#### Text Objects: Examples

```lua
1  local DoubleSumTo = function(number)
2
3      local sum = 0
4      for i = 1, number do
5          print("This is the " .. i .. "-th loop")
6
7          for j = 1, number do
8              print("This is the " .. j .. "-th inner loop.")
9              sum = i + j
10         end
11
12     end
13
14     print("The sum is " .. sum)
15     return sum
16 end
```

- If the cursor is on line 7, `viI` selects line  7. (`strict` text block)
- If the cursor is on line 7, `vii` selects lines 5-10.
- If the cursor is on line 7, `vai` selects lines 4-10.
- If the cursor is on line 7, `vaI` selects lines 4-12.
- If the cursor is on line 7, `v1ii` selects lines 3-15. (one extra indent level)
- If the cursor is on line 7, `v1ai` selects lines 1-15. (one extra indent level)
- If the cursor is on line 7, `v1aI` selects lines 1-16. (one extra indent level)
- If the cursor is on line 8, `v2ii` selects lines 3-15. (two extra indent levels)
- If the cursor is on line 8, `v2ai` selects lines 1-15. (two extra indent levels)
- If the cursor is on line 8, `v2aI` selects lines 1-16. (two extra indent levels)

## Global Settings

| Setting               | Value                      | Description                                                    |
| :---                  | :---                       | :---                                                           |
| `vim.g.vindent_begin` | boolean (default: `true`)  | whether to move cursor to the beginning of line after a motion |
| `vim.g.vindent_jumps` | boolean (default: `true`)  | whether a motion is added to the jumplist                      |
| `vim.g.vindent_noisy` | boolean (default: `false`) | whether motion throws an error if the cursor does not move     |
| `vim.g.vindent_infer` | boolean (default: `false`) | whether to infer indent of empty lines by context              |

You can also use the function `setup` (as shown in [quick start](#installation-and-quick-start)) to set these variables.

## Licence

Distributed under the same terms as Vim itself. See `:help license`.
