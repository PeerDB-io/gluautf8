package gluautf8

import (
	"testing"

	"github.com/yuin/gopher-lua"
)

func Test_UTF8(t *testing.T) {
	ls := lua.NewState(lua.Options{})
	ls.PreloadModule("utf8", Loader)
	if err := ls.DoFile("utf8.lua"); err != nil {
		t.Log(err)
		t.FailNow()
	}
}
