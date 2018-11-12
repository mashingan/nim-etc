# compile:
# > nim c -r monitorfile.nim
import winlean

const
  FILE_NOTIFY_CHANGE_FILE_NAME* = 0x00000001'i32
  FILE_NOTIFY_CHANGE_DIR_NAME* = 0x00000002'i32
  FILE_NOTIFY_CHANGE_ATTRIBUTES* = 0x00000004'i32
  FILE_NOTIFY_CHANGE_SIZE* = 0x00000008'i32
  FILE_NOTIFY_CHANGE_LAST_WRITE* = 0x00000010'i32
  FILE_NOTIFY_CHANGE_SECURITY* = 0x00000100'i32

{.push dynlib: "kernel32.dll", stdcall.}
proc findFirstChangeNotification(pathname: cstring, watchSubtree: bool,
  notifFilter: int32): HANDLE {.importc: "FindFirstChangeNotificationA".}

proc findNextChangeNotification(handle: HANDLE): WINBOOL
  {.importc:"FindNextChangeNotification".}
{.pop.}


proc quit(value: DWORD) =
  quit value.int

proc refreshDirectory(handle: var HANDLE) =
  handle = findFirstChangeNotification(".", false,
    FILE_NOTIFY_CHANGE_FILE_NAME + FILE_NOTIFY_CHANGE_SIZE +
    FILE_NOTIFY_CHANGE_LAST_WRITE)
  if handle == INVALID_HANDLE_VALUE:
    quit getLastError()

proc refreshTree(handle: var HANDLE) =
  handle = findFirstChangeNotification(".", true,
    FILE_NOTIFY_CHANGE_DIR_NAME)

proc waitForMultipleObjects(count: int, handles: var openArray[HANDLE],
    waitAll: bool, timeout: int32): int =
  echo "to wait for multiple objects"
  winlean.waitForMultipleObjects(count.DWORD, cast[PWOHandleArray](addr handles[0]),
    waitAll.WINBOOL, cast[DWORD](timeout)).int

proc main =
  var
    waitStatus: int
    changeHandles: array[2, HANDLE]

  refreshDirectory(changeHandles[0])
  if changeHandles[0] == INVALID_HANDLE_VALUE:
    echo "invalid handle value in refresh directory"
    quit getLastError()
  refreshTree(changeHandles[1])
  if changeHandles[1] == INVALID_HANDLE_VALUE:
    echo "invalid handle value in refresh tree"
    quit getLastError()

  echo "Start watching current directory"
  while true:
    # can handle INFINITE if doing in different thread
    waitStatus = waitForMultipleObjects(2, changeHandles, false, 1000)
    case waitStatus
    of WAIT_OBJECT_0:
      echo "A file was created or deleted in this directory"
      #refreshDirectory(changeHandles[0])
      if findNextChangeNotification(changeHandles[0]) == 0:
        var lasterror = getLastError()
        echo "lasterror: ", lasterror
        quit getLastError()
      #break
    of WAIT_OBJECT_0 + 1:
      echo "A folder was created or deleted in this directory"
      #refreshTree(changeHandles[1])
      if findNextChangeNotification(changeHandles[1]) == 0:
        var lasterror = getLastError()
        echo "lasterror: ", lasterror
        quit getLastError()
      #break

    of WAIT_TIMEOUT:
      echo "Nothing happened until time out happened"

    else:
      echo "Into default post"
      quit getLastError()

when isMainModule:
  main()
