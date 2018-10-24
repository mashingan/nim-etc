include karax / prelude
import karax/[errors, kajax, kdom]
import json, httpcore, strformat
import jsffi except `&`
import sugar

type Validator = proc(field: kstring): proc()
proc loginField(desc, field, class: kstring, handle: Validator, `type` = "text"): VNode =
  result = buildHtml tdiv:
    label(`for` = field): text desc
    input(class = class, id = field, `type`=`type`, oninput = handle(field))

proc validateNotEmpty(field: kstring): proc() =
  result = proc() =
    let x = getVNodeById field
    if x.text == "":
      setError(field, field & " must not be empty")
    else:
      setError(field, "")

const
  username = kstring"username"
  password = kstring"password"

type
  LoginInfo = object
    user: UserInfo
    menu: seq[string]

  UserInfo = object
    username: string
    sessid: int

var
  loggingIn = false
  authenticated = false
  timer: Timeout
  loginMessage = ""
  loginInfo: LoginInfo

proc listMenu(list: seq[string]): VNode =
  if list.len != 0:
    result = buildHtml(tdiv()):
      ol:
        for menu in list:
          li: text menu

proc loggedIn(linfo: LoginInfo): VNode =
  result = buildHtml(tdiv()):
    listmenu(linfo.menu)

    p: text fmt"Your login session id is {linfo.user.sessid}"


proc loginDialog: VNode =
  proc loginCb(status: int, response: cstring) =
    loggingIn = false
    if status >= Http400.int:
      authenticated = false
      loginMessage = $response
    else:
      loginMessage = "login success"
      authenticated = true
      loginInfo = ($response).parseJson.to LoginInfo
      echo loginInfo
      timer = setTimeout((proc() =
        authenticated = false
        ), 1000 * 60)

  var loginpage = buildHtml tdiv:
    if not authenticated:
      p: text loginMessage
    loginField("Username", username, "input", validateNotEmpty)
    loginFIeld("Password", password, "password", validateNotEmpty, "password")
    button(disabled = disableOnError(), onclick = proc() =
      let
        uname = getVNodeById(username).text
        pass = getVNodeById(password).text
      loggingIn = true
      ajaxPost("/login",
        [(kstring"content-type", kstring"application/json")],
        $(%* {"username": $uname, "password": $pass }),
        loginCb)
    ): text "Login"
    p: text $getError(username)
    p: text $getError(password)

  var loggingPage = buildHtml tdiv:
    p: text "You're logging in, waiting for authentication"

  if loggingIn:
    result = buildHtml tdiv:
      p: text "You're logging in, waiting for authentication"
  elif authenticated:
    result = loggedIn loginInfo
  else:
    result = loginpage

setError username, username & " must be not empty"
setError password, password & " must be not empty"
setRenderer loginDialog
