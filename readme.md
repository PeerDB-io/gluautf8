# utf8 for gopher-lua

Implements Lua 5.3 [utf8](https://www.lua.org/manual/5.3/manual.html#6.5) for [gopher-lua](https://github.com/yuin/gopher-lua). To use, call
```go
import (
	"github.com/PeerDB-io/gluautf8"
)

// add so that `local utf8 = require("utf8")` works
L.PreloadModule("utf8", gluautf8.Loader)

// or add to global env
L.Push(ls.NewFunction(gluautf8.Loader))
L.Call(0, 1)
L.Env.RawSetString("utf8", L.Get(-1))
L.Pop(1)
```
