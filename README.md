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

> [!NOTE]
> This plugin is the Lua version of
> [`vindent.vim`](https://github.com/jessekelighine/vindent.vim), which was
> written in Vimscript. The two plugins are practically the same, with minor
> differences in naming and default settings. I find it a bit easier to deal
> with edge cases in Lua, thus why this plugin is created.

> [!NOTE]
> The [`experimental`](https://github.com/jessekelighine/vindent.nvim/tree/experimental) branch
> explores an alternative approach to defining key mappings (avoiding the use of `<Plug>`),
> which may feel more intuitive and less vimscript-ish.

## Installation and Quick Start

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
	"jessekelighine/vindent.nvim",
	config = function()
		local map = {
			motion = function(lhs, rhs) vim.keymap.set("", lhs, rhs) end,
			object = function(lhs, rhs) vim.keymap.set({ "x", "o" }, lhs, rhs) end,
		}
		map.motion("[=", "<Plug>(VindentBlockMotion_OO_prev)")
		map.motion("]=", "<Plug>(VindentBlockMotion_OO_next)")
		map.motion("[+", "<Plug>(VindentMotion_more_prev)")
		map.motion("]+", "<Plug>(VindentMotion_more_next)")
		map.motion("[-", "<Plug>(VindentMotion_less_prev)")
		map.motion("]-", "<Plug>(VindentMotion_less_next)")
		map.motion("[;", "<Plug>(VindentMotion_diff_prev)")
		map.motion("];", "<Plug>(VindentMotion_diff_next)")
		map.motion("[p", "<Plug>(VindentBlockEdgeMotion_XX_prev)")
		map.motion("]p", "<Plug>(VindentBlockEdgeMotion_XX_next)")
		map.object("ii", "<Plug>(VindentObject_XX_ii)")
		map.object("ai", "<Plug>(VindentObject_XX_ai)")
		map.object("aI", "<Plug>(VindentObject_XX_aI)")
	end
},
```

With these keybindings, you can now...

1. **Vindent Motions**:
	- Jump to previous/next block with same indentation with `[=`/`]=`. ([examples](#block-wise-motions))
	- Jump to previous/next line with less indentation with `[-`/`]-`. ([examples](#line-wise-motions))
	- Jump to previous/next line with more indentation with `[+`/`]+`. ([examples](#line-wise-motions))
	- Jump to previous/next line with different indentation with `[;`/`];`. ([examples](#line-wise-motions))
	- Jump to start/end of text block with `[p`/`]p`. ([examples](#block-wise-motions))
2. **Vindent Text Objects**: Select text block with `ii` (*in indent*),`ai`
   (*an indent*), and `aI` (*an Indent*). ([examples](#text-objects))

## Usage

In this section, we will assume that the keybindings defined in
[quick start](#installation-and-quick-start) are used for all the examples.

### Line-wise Motions

These motions are self explanatory: move to the previous or next line with
*same*, *less*, *more*, or *different* indentation.

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

#### Line-wise Motions: Full List

```vim
<Plug>(VindentMotion_more_prev)
<Plug>(VindentMotion_more_next)
<Plug>(VindentMotion_less_prev)
<Plug>(VindentMotion_less_next)
<Plug>(VindentMotion_diff_prev)
<Plug>(VindentMotion_diff_next)
<Plug>(VindentMotion_same_prev)
<Plug>(VindentMotion_same_next)
```

### Block-wise Motions

`vindent.nvim` provides two types of text objects:

| Motion            | Description                                         |
| :---              | :---                                                |
| `BlockMotion`     | move to the previous/next text block of same indent |
| `BlockEdgeMotion` | move to the beginning/end of current text block     |

All motions and objects that operates *block-wise* contains a two-character
string of `O`'s and `X`'s in their names. This string indicates how the motion
or object defines a "text block". The first character indicates whether "empty
lines" are considered to be boundaries of a text block. The second character
indicates whether "lines with more indentation" are considered boundaries of a
text block. That is, a/an

|      | Empty line         | More-indented line |
| :--- | :---               | :---               |
| `OO` | is **NOT** skipped | is **NOT** skipped |
| `XO` | is skipped         | is **NOT** skipped |
| `OX` | is **NOT** skipped | is skipped         |
| `XX` | is skipped         | is skipped         |

when searching for boundaries of a text block. 
See the example below.

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
6 and 8. This is because `]=` is mapped to `<Plug>(VindentBlockMotion_OO_next)`,
where `OO` indicates that "empty lines" and "more-indented lines" are all
considered to be boundaries of a text block. So lines 2-3 is one block, line 6
is itself a block, and lines 8-9 is the third block.

If the cursor is on line 2, then pressing `]p` moves the cursor to line 9. This
is because `]p` is mapped to `<Plug>(VindentBlockEdgeMotion_XX_next)`, where
`XX` indicates that "empty lines" and "more-indented lines" are all skipped
(not boundaries), thus line 2 to line 9 is considered to be one text block.

#### Block-wise Motions: Full List

```vim
<Plug>(VindentBlockMotion_OO_prev)
<Plug>(VindentBlockMotion_OO_next)
<Plug>(VindentBlockMotion_XO_prev)
<Plug>(VindentBlockMotion_XO_next)
<Plug>(VindentBlockMotion_OX_prev)
<Plug>(VindentBlockMotion_OX_next)
<Plug>(VindentBlockMotion_XX_prev)
<Plug>(VindentBlockMotion_XX_next)

<Plug>(VindentBlockEdgeMotion_OO_prev)
<Plug>(VindentBlockEdgeMotion_OO_next)
<Plug>(VindentBlockEdgeMotion_XO_prev)
<Plug>(VindentBlockEdgeMotion_XO_next)
<Plug>(VindentBlockEdgeMotion_OX_prev)
<Plug>(VindentBlockEdgeMotion_OX_next)
<Plug>(VindentBlockEdgeMotion_XX_prev)
<Plug>(VindentBlockEdgeMotion_XX_next)
```

### Text Objects

`vindent.nvim` provides three types of text objects:

| Text Object | Mnemonics   | Description                                                                  |
| :---        | :---        | :---                                                                         |
| `ii`        | *in indent* | select block of same indent                                                  |
| `ai`        | *an indent* | select block of same indent plus a previous line with less indent            |
| `aI`        | *an Indent* | select block of same indent plus a previous and a next line with less indent |

Object `ai` is useful for selecting something like a Python function, and `aI`
is useful for selecting something like a Lua function. As detailed in
[block-wise motions](#block-wise-motions), you can change what is
considered to be a *text block* by changing the `O`'s and `X`'s in the `<Plug>` names.
Also, all text objects can take `[count]`, which makes the text objects select
`[count]` additional indent levels around. See the example below.

#### Text Objects: Examples

```lua
 1 local SumTo = function(number)
 2
 3     local sum = 0
 4     for time = 1, number do
 5         print("This is the " .. time .. "-th time.")
 6         sum = sum + time
 7     end
 8
 9     print("The sum is " .. sum)
10     return sum
11 end
```

- If the cursor is on line 3, `vii` selects lines 3-10.
- If the cursor is on line 3, `vai` selects lines 1-10.
- If the cursor is on line 3, `vaI` selects lines 1-11.
- If the cursor is on line 5, `v1ii` selects lines 3-10. (one extra indent level)
- If the cursor is on line 5, `v1ai` selects lines 1-10. (one extra indent level)
- If the cursor is on line 5, `v1aI` selects lines 1-11. (one extra indent level)

```lua
1  {
2      "jessekelighine/vindent.nvim",
3      config = function()
4          local map = {
5              motion = function(lhs, rhs) vim.keymap.set("", lhs, rhs) end,
6              object = function(lhs, rhs) vim.keymap.set({ "x", "o" }, lhs, rhs) end,
7          }
8          map.motion("[=", "<Plug>(VindentBlockMotion_OO_prev)")
9          map.motion("]=", "<Plug>(VindentBlockMotion_OO_next)")
10         map.motion("[+", "<Plug>(VindentMotion_more_prev)")
11         map.motion("]+", "<Plug>(VindentMotion_more_next)")
12         map.motion("[-", "<Plug>(VindentMotion_less_prev)")
13         map.motion("]-", "<Plug>(VindentMotion_less_next)")
14         map.motion("[;", "<Plug>(VindentMotion_diff_prev)")
15         map.motion("];", "<Plug>(VindentMotion_diff_next)")
16         map.motion("[p", "<Plug>(VindentBlockEdgeMotion_XX_prev)")
17         map.motion("]p", "<Plug>(VindentBlockEdgeMotion_XX_next)")
18         map.object("ii", "<Plug>(VindentObject_XX_ii)")
19         map.object("ai", "<Plug>(VindentObject_XX_ai)")
20         map.object("aI", "<Plug>(VindentObject_XX_aI)")
21     end
22 },
```

- If the cursor is on line 5, `vii` selects lines 5-6.
- If the cursor is on line 5, `vaI` selects lines 4-7.
- If the cursor is on line 5, `v1ii` selects lines 4-20. (one extra indent level)
- If the cursor is on line 5, `v1aI` selects lines 3-21. (one extra indent level)
- If the cursor is on line 5, `v2ii` selects lines 2-21. (two extra indent levels)
- If the cursor is on line 5, `v2aI` selects lines 1-22. (two extra indent levels)

#### Text Objects: Full List

```vim
<Plug>(VindentObject_OO_ii)
<Plug>(VindentObject_OX_ii)
<Plug>(VindentObject_XO_ii)
<Plug>(VindentObject_XX_ii)
<Plug>(VindentObject_OO_ai)
<Plug>(VindentObject_OX_ai)
<Plug>(VindentObject_XO_ai)
<Plug>(VindentObject_XX_ai)
<Plug>(VindentObject_OO_aI)
<Plug>(VindentObject_OX_aI)
<Plug>(VindentObject_XO_aI)
<Plug>(VindentObject_XX_aI)
```

## Global Settings

| Setting               | Value                      | Description                                                    |
| :---                  | :---                       | :---                                                           |
| `vim.g.vindent_begin` | boolean (default: `true`)  | whether to move cursor to the beginning of line after a motion |
| `vim.g.vindent_jumps` | boolean (default: `true`)  | whether a motion is added to the jumplist                      |
| `vim.g.vindent_noisy` | boolean (default: `false`) | whether motion throws an error if the cursor does not move     |
| `vim.g.vindent_infer` | boolean (default: `false`) | whether to infer indent of empty lines by context              |

## Licence

Distributed under the same terms as Vim itself. See `:help license`.
