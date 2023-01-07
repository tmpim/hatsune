# hatsune

computercraft i/o library for people who like vocaloid

(also it's cute like miku)

## what's in the box?
 - `hatsune` - cute event loop and coroutine scheduler
 - `miku` - future/promise implementation
 - `async` - create a miku from a yielding/awaiting function, instead of using miku callbacks
 - `await` - await a miku, also available as `miku:await`
 - `awaitSafe` - await a miku, catching errors and returning `boolean, result`, also available as `miku:awaitSafe`

## examples

### [moonscript](./examples/moonscript)

the preferable language for hatsune is moonscript, since it allows for much more concise code. here are some examples:

 - [hatsune](./examples/moonscript/hatsune.moon)
 - [miku](./examples/moonscript/miku.moon)

### [lua](./examples/lua)

as a lua library, hatsune is a bit more verbose (but still easy to use!). here are some examples:

 - [hatsune](./examples/lua/hatsune.lua)
 - [miku](./examples/lua/miku.lua)

## installation

from computercraft, run the following command:

```
wget https://github.com/tmpim/hatsune/raw/main/hatsune.lua
```

## building

to build the library, [moonscript-cc](https://github.com/emmachase/moonscript-cc) to build the library in-game, or use the standard [moonscript](https://moonscript.org/) compiler to build it on your computer. once you have either of those, run the following command:

```
moonc hatsune.moon
```

## todo
 - http library
 - websocket library
 - krist library
 - more examples
