# example of using enum as bitfield together with set
# in this case, it's the unix style file permission

import os, strformat, strutils
from unicode import reversed

type
  ActionType = enum
    atExec atWrite atRead

# https://forum.nim-lang.org/t/5270#33119
proc unixPermission(file: string): string =
  let info = getFileInfo(file, followSymlink = false)
  result &= [pcFile: '-', 'l', pcDir: 'd', 'l'][info.kind]
  for i, p in [fpUserRead, fpUserWrite, fpUserExec,
               fpGroupRead, fpGroupWrite, fpGroupExec,
               fpOthersRead, fpOthersWrite, fpOthersExec]:
    result &= (if p in info.permissions: "rwx"[i mod 3] else: '-')

converter unixStyle(perm: set[FilePermission]): string =
  let permstring = fmt"{cast[uint16](perm):o}".reversed
  result = "-"
  for c in permstring:
    let permbool = cast[set[ActionType]](c.ord - '0'.ord)
    result &= (if atRead in permbool: 'r' else: '-')
    result &= (if atWrite in permbool: 'w' else: '-')
    result &= (if atExec in permbool: 'x' else: '-')

converter toNum(perm: set[FilePermission]): int =
  (fmt"{cast[uint16](perm):o}").reversed.parseOctInt

let perms = {fpUserWrite, fpUserRead, fpGroupWrite, fpGroupRead, fpOthersRead}
let permstring: string = perms
echo fmt"{perms}: {permstring}"
echo fmt"{perms}: {perms.unixStyle}"

stdout.write "permission?: "
let filepermission: string = cast[set[FilePermission]](stdin.readLine.strip.reversed.parseOctInt)
echo fmt"file permission: {filepermission}"
