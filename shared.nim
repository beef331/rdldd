import std/[posix, oserrors]

type Mode* = enum
  XOther
  WOther
  ROther

  XGroup
  WGroup
  RGroup

  XUser
  WUser
  RUser

  SaveSwapped
  SetGroupIdOnExec
  SetUserId


const mapped =
  [
    XOther: S_IXOTH,
    WOther: S_IWOTH,
    ROther: S_IROTH,
    XGroup: S_IXGRP,
    WGroup: S_IWGRP,
    RGroup: S_IRGRP,
    XUser: S_IXUSR,
    WUser: S_IWUSR,
    RUser: S_IRUSR]

proc createNamedPipe*(name: string, mode: set[Mode]) =
  var flags = default(cint)
  for x in mode:
    flags = flags or mapped[x]

  if mkfifo(cstring name, posix.Mode(flags)) == -1:
    raiseOserror(osLastError())
