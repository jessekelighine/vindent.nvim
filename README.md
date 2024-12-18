# vindent.nvim

`vindent.nvim` is Neovim plugin that provides indentation related *motions* and *text objects*:

1. **Motions**: jump to specific positions defined by indentations.
	- Jump to previous/next line with *same*, *less*, *more*, or *different* indentation.
	- Jump to previous/next text block with *same* indentation.
	- Jump to start/end of the current text block of same indentation.
2. **Text Objects**: selects specific lines defined by indentations.
	- Select a text block of *same* (or specified level of) indentation.
	- Select text block and a previous line with less indentation. (useful with languages like Python)
	- Select text block, a previous, and a next line with less indentation. (useful with languages like Lua)

> **NOTE**: This plugin is the Lua version of [vindent.vim](https://github.com/jessekelighine/vindent.vim),
> which was written in Vimscript.
> The two plugins are practically the same, with minor differences in naming and [default settings](#global-settings).
> I find it a bit easier to deal with edge cases in Lua, thus the reason why this plugin is created.

## Installation and Quick Start

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
	"jessekelighine/vindent.nvim",
	config = function()
		-- Here are some sensible default keybindings:
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
	- Jump to previous/next block with same indentation with `[=`/`]=`. ([examples](#vindent-motion-block-wise))
	- Jump to previous/next line with less indentation with `[-`/`]-`. ([examples](#vindent-motion-line-wise))
	- Jump to previous/next line with more indentation with `[+`/`]+`. ([examples](#vindent-motion-line-wise))
	- Jump to previous/next line with different indentation with `[;`/`];`. ([examples](#vindent-motion-line-wise))
	- Jump to start/end of text block with `[p`/`]p`. ([examples](#vindent-motion-block-wise))
2. **Vindent Text Objects**:
   Select text block with `ii` (*in indent*),`ai` (*an indent*), and `aI` (*an Indent*). ([examples](#vindent-text-object))

## Usage

### Vindent Motion: line-wise

These motions are very self explanatory: move to the previous or next line with
either *same*, *less*, *more*, or *different* indentation.  These motions
operates on *entire lines* if it is prepended with a normal command such as `d`
or `c` or `y`.

For example, assume that the keybindings in [quick start](#installation-and-quick-start) are
used and consider the following python code:

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

Here are all the line-wise motions:

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

### Vindent Motion: block-wise

These motions move the cursor to the previous or next text block with the same indentation.
All motions or objects that operates block-wise contains a two character string of `O`'s and `X`'s in their names.
This string indicates how the motion or object defines a "text block".
The first character indicates whether "empty lines" are considered to be boundaries of a text block.
The second character indicates whether "lines with more indentation" are considered boundaries of a text block.
That is,

|      | Empty line          | More-indented line  |
|------|---------------------|---------------------|
| `OO` | is boundary         | is boundary         |
| `XO` | is **NOT** boundary | is boundary         |
| `OX` | is boundary         | is **NOT** boundary |
| `XX` | is **NOT** boundary | is **NOT** boundary |

Here are some examples to clear things up.  Assume that the keybindings in
[quick start](#installation-and-quick-start) are used and consider the following code:

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

If the cursor is on line 2, then pressing `]=` 2 times moves the cursor to line 6 and 8.
This is because `]=` is mapped to `<Plug>(VindentBlockMotion_OO_next)`,
in which `OO` indicates that "empty lines" and "more-indented lines"
are all considered to be boundaries of a text block.
So lines 2-3 is one block, line 6 is itself a block, and lines 8-9 is the third block.

If the cursor is on line 2, then pressing `]p` moves the cursor to line 9.
This is because `]p` is mapped to `<Plug>(VindentBlockEdgeMotion_XX_next)`,
in which `XX` indicates that "empty lines" and "more-indented lines" are all ignored
(not boundaries),
thus line 2 to line 9 is considered to be one text block.

Here are all the block-wise motions:

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

### Vindent Text Object

The text objects are:

| Text Object | Mnemonics   | Description                                                                                 |
|-------------|-------------|---------------------------------------------------------------------------------------------|
| `ii`        | *in indent* | select text block of same indentation.                                                      |
| `ai`        | *an indent* | select text block of same indentation and a previous line with less indentation.            |
| `aI`        | *an Indent* | select text block of same indentation and a previous and a next line with less indentation. |

Similar to [block-wise motions](#vindent-motion-block-wise), you can specify
what is considered to be the same block by changing the `O`'s and `X`'s in the
variable name.

The text objects can take counts, which indicates how make levels up (of
indents) should be selected.  Assume that the keybindings in
[quick start](#installation-and-quick-start) are used and consider following code:

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
- If the cursor is on line 5, `v1ii` selects lines 3-10. (one more indent level)
- If the cursor is on line 5, `v1ai` selects lines 1-10. (one more indent level, and then search for a previous line with less indentation)

Here are all the text objects:

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

Here are some global settings.

| Setting/Variable | Value | Description |
|----|----|----|
| `vim.g.vindent_begin` | boolean (default: `true`) | whether to move cursor to the beginning of line after a vindent motion |
| `vim.g.vindent_jumps` | boolean (default: `true`) | whether a vindent motion is added to the jumplist |
| `vim.g.vindent_noisy` | boolean (default: `false`) | whether vindent motion throws an error if the cursor does not move |
| `vim.g.vindent_infer` | boolean (default: `false`) | whether vindent tries to infer indentation of empty lines by context, i.e., by determining the indentations of nearby lines |

## Licence

Distributed under the same terms as Vim itself. See `:help license`.
