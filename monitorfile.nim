# compile:
# > nim c -r monitorfile.nim
import winim

proc quit(value: DWORD) =
  quit value.int

proc refreshDirectory(handle: var HANDLE) =
  handle = FindFirstChangeNotification(".", false,
    FILE_NOTIFY_CHANGE_FILE_NAME)
  if handle == INVALID_HANDLE_VALUE:
    quit GetLastError()

proc refreshTree(handle: var HANDLE) =
  handle = FindFirstChangeNotification(".", true,
    FILE_NOTIFY_CHANGE_DIR_NAME)

proc waitForMultipleObjects(count: int, handles: var openArray[HANDLE],
    waitAll: bool, timeout: int32): int =
  WaitForMultipleObjects(count.DWORD, addr handles[0], waitAll,
    cast[DWORD](timeout)).int

proc main =
  var
    waitStatus: int
    changeHandles: array[2, HANDLE]

  refreshDirectory(changeHandles[0])
  if changeHandles[0] == INVALID_HANDLE_VALUE:
    echo "invalid handle value"
    quit GetLastError()
  refreshTree(changeHandles[1])
  if changeHandles[1] == INVALID_HANDLE_VALUE:
    echo "invalid handle value"
    quit GetLastError()

  echo "Start watching current directory"
  while true:
    waitStatus = waitForMultipleObjects(2, changeHandles, false, INFINITE)
    case waitStatus
    of WAIT_OBJECT_0:
      echo "A file was created or deleted in this directory"
      #refreshDirectory(changeHandles[0])
      if FindNextChangeNotification(changeHandles[0]) == 0:
        var lasterror = GetLastError()
        echo "lasterror: ", lasterror
        quit GetLastError()
      #break
    of WAIT_OBJECT_0 + 1:
      echo "A folder was created or deleted in this directory"
      #refreshTree(changeHandles[1])
      if FindNextChangeNotification(changeHandles[1]) == 0:
        var lasterror = GetLastError()
        echo "lasterror: ", lasterror
        quit GetLastError()
      #break

    else:
      echo "Into default post"
      quit GetLastError()

when isMainModule:
  main()
