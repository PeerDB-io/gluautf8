-- $Id: utf8.lua,v 1.12 2016/11/07 13:11:28 roberto Exp $
-- *****************************************************************************
-- * Copyright (C) 1994-2016 Lua.org, PUC-Rio.
-- *
-- * Permission is hereby granted, free of charge, to any person obtaining
-- * a copy of this software and associated documentation files (the
-- * "Software"), to deal in the Software without restriction, including
-- * without limitation the rights to use, copy, modify, merge, publish,
-- * distribute, sublicense, and/or sell copies of the Software, and to
-- * permit persons to whom the Software is furnished to do so, subject to
-- * the following conditions:
-- *
-- * The above copyright notice and this permission notice shall be
-- * included in all copies or substantial portions of the Software.
-- *
-- * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- *****************************************************************************

-- Modified by github.com/serprex for Lua 5.1 compatibility

print "testing UTF-8 library"

local utf8 = require'utf8'


local function checkerror (msg, f, ...)
  local s, err = pcall(f, ...)
  assert(not s and string.find(err, msg))
end


local function len (s)
  return #string.gsub(s, string.char(91, 0x80, 45, 0xbf, 93), "")
end


local justone = "^" .. utf8.charpattern .. "$"

assert(utf8.offset("alo", 5) == nil)
assert(utf8.offset("alo", -4) == nil)

-- 't' is the list of codepoints of 's'
local function check (s, t)
  local l = utf8.len(s)
  assert(#t == l and len(s) == l)
  assert(utf8.char(unpack(t)) == s)

  assert(utf8.offset(s, 0) == 1)

  local t1 = {utf8.codepoint(s, 1, -1)}
  assert(#t == #t1)
  for i = 1, #t do assert(t[i] == t1[i]) end

  for i = 1, l do
    local pi = utf8.offset(s, i)        -- position of i-th char
    local pi1 = utf8.offset(s, 2, pi)   -- position of next char
    assert(string.find(string.sub(s, pi, pi1 - 1), justone))
    assert(utf8.offset(s, -1, pi1) == pi)
    assert(utf8.offset(s, i - l - 1) == pi)
    assert(pi1 - pi == #utf8.char(utf8.codepoint(s, pi)))
    for j = pi, pi1 - 1 do
      assert(utf8.offset(s, 0, j) == pi)
    end
    for j = pi + 1, pi1 - 1 do
      assert(not utf8.len(s, j))
    end
   assert(utf8.len(s, pi, pi) == 1)
   assert(utf8.len(s, pi, pi1 - 1) == 1)
   assert(utf8.len(s, pi) == l - i + 1)
   assert(utf8.len(s, pi1) == l - i)
   assert(utf8.len(s, 1, pi) == i)
  end

  local i = 0
  for p, c in utf8.codes(s) do
    i = i + 1
    assert(c == t[i] and p == utf8.offset(s, i))
    assert(utf8.codepoint(s, p) == c)
  end
  assert(i == #t)

  i = 0
  for p, c in utf8.codes(s) do
    i = i + 1
    assert(c == t[i] and p == utf8.offset(s, i))
  end
  assert(i == #t)

  i = 0
  for c in string.gmatch(s, utf8.charpattern) do
    i = i + 1
    assert(c == utf8.char(t[i]))
  end
  assert(i == #t)

  for i = 1, l do
    assert(utf8.offset(s, i) == utf8.offset(s, i - l - 1, #s + 1))
  end

end


do    -- error indication in utf8.len
  local function check (s, p)
    local a, b = utf8.len(s)
    assert(not a and b == p)
  end
  check("abc" .. string.char(0xE3) .. "def", 4)
  check("汉字" .. string.char(0x80), #("汉字") + 1)
  check(string.char(0xF4, 0x9F, 0xBF), 1)
  check(string.char(0xF4, 0x9F, 0xBF, 0xBF), 1)
end

-- error in utf8.codes
checkerror("invalid UTF%-8 code",
  function ()
    local s = "ab" .. string.char(0xff)
    for c in utf8.codes(s) do assert(c) end
  end)


-- error in initial position for offset
checkerror("position out of range", utf8.offset, "abc", 1, 5)
checkerror("position out of range", utf8.offset, "abc", 1, -4)
checkerror("position out of range", utf8.offset, "", 1, 2)
checkerror("position out of range", utf8.offset, "", 1, -1)
checkerror("continuation byte", utf8.offset, "𦧺", 1, 2)
checkerror("continuation byte", utf8.offset, "𦧺", 1, 2)
checkerror("continuation byte", utf8.offset, string.char(0x80), 1)



local s = "hello World"
local t = {string.byte(s, 1, -1)}
for i = 1, utf8.len(s) do assert(t[i] == string.byte(s, i)) end
check(s, t)

check("汉字/漢字", {27721, 23383, 47, 28450, 23383,})

do
  local s = "áéí\128"
  local t = {utf8.codepoint(s,1,#s - 1)}
  assert(#t == 3 and t[1] == 225 and t[2] == 233 and t[3] == 237)
  checkerror("invalid UTF%-8 code", utf8.codepoint, s, 1, #s)
  checkerror("out of range", utf8.codepoint, s, #s + 1)
  t = {utf8.codepoint(s, 4, 3)}
  assert(#t == 0)
  checkerror("out of range", utf8.codepoint, s, -(#s + 1), 1)
  checkerror("out of range", utf8.codepoint, s, 1, #s + 1)
end

assert(utf8.char() == "")
assert(utf8.char(97, 98, 99) == "abc")

assert(utf8.codepoint(utf8.char(0x10FFFF)) == 0x10FFFF)

checkerror("value out of range", utf8.char, 0x10FFFF + 1)

local function invalid (s)
  checkerror("invalid UTF%-8 code", utf8.codepoint, s)
  assert(not utf8.len(s))
end

-- UTF-8 representation for 0x11ffff (value out of valid range)
invalid(string.char(0xF4, 0x9F, 0xBF, 0xBF))

-- overlong sequences
invalid(string.char(0xC0, 0x80))          -- zero
invalid(string.char(0xC1, 0xBF))          -- 0x7F (should be coded in 1 byte)
invalid(string.char(0xE0, 0x9F, 0xBF))      -- 0x7FF (should be coded in 2 bytes)
invalid(string.char(0xF0, 0x8F, 0xBF, 0xBF))  -- 0xFFFF (should be coded in 3 bytes)


-- invalid bytes
invalid(string.char(0x80))  -- continuation byte
invalid(string.char(0xBF))  -- continuation byte
invalid(string.char(0xFE))  -- invalid byte
invalid(string.char(0xFF))  -- invalid byte


-- empty string
check("", {})

-- minimum and maximum values for each sequence size
s = string.char(0x0,0x7f,0xc2,0x80,0xdf,0xbf,0xe0,0xa0,0x80,0xef,0xbf,0xbf,0xf0,0x90,0x80,0x80,0xf4,0x8f,0xbf,0xbf)
check(s, {0,0x7F, 0x80,0x7FF, 0x800,0xFFFF, 0x10000,0x10FFFF})

x = "日本語a-4\0éó"
check(x, {26085, 26412, 35486, 97, 45, 52, 0, 233, 243})


-- Supplementary Characters
check("𣲷𠜎𠱓𡁻𠵼ab𠺢",
      {0x23CB7, 0x2070E, 0x20C53, 0x2107B, 0x20D7C, 0x61, 0x62, 0x20EA2,})

check("𨳊𩶘𦧺𨳒𥄫𤓓" .. string.char(0xF4, 0x8F, 0xBF, 0xBF),
      {0x28CCA, 0x29D98, 0x269FA, 0x28CD2, 0x2512B, 0x244D3, 0x10ffff})


local i = 0
for p, c in string.gmatch(x, "()(" .. utf8.charpattern .. ")") do
  i = i + 1
  assert(utf8.offset(x, i) == p)
  assert(utf8.len(x, p) == utf8.len(x) - i + 1)
  assert(utf8.len(c) == 1)
  for j = 1, #c - 1 do
    assert(utf8.offset(x, 0, p + j - 1) == p)
  end
end

print'ok'

