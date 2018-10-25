include karax / prelude
import karax/[errors, kajax, kdom, localstorage, vstyles]
import json, httpcore, strformat
#import jsffi except `&`
import sugar
import strutils as sutl

import types

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
  userreg = kstring"ureg"
  passreg = kstring"preg"

proc isAuthenticated(): bool =
  if hasItem("authenticated"):
    result = sutl.parseBool($getItem("authenticated"))
  else:
    result = false

proc setAuthenticated() =
  setItem("authenticated", &true)

proc revokeAuthentication() =
  setItem("authenticated", &false)

var
  loggingIn = false
  authenticated = isAuthenticated()
  timer: Timeout
  loginMessage = ""
  loginInfo: LoginInfo =
    if hasItem("loginInfo"):
      ($getItem("loginInfo")).parseJson.to(LoginInfo)
    else: LoginInfo()
  register = false

proc listMenu(list: seq[Menu]): VNode =
  if list.len != 0:
    result = buildHtml(tdiv()):
      ol:
        for menu in list:
          li: a(href=menu.href): text menu.label

proc genericPage(info: string): VNode =
  result = buildHtml(tdiv()):
    p: text info
    p: a(href="#/user"): text "Back"

proc loggedIn(linfo: LoginInfo, route: cstring): VNode =
  proc logoutCb(status: int, response: cstring) =
    loginMessage = $response
    if status >= Http200.int and status < Http400.int:
      authenticated = false
      revokeAuthentication()
      removeItem("loginInfo")
      window.location.replace(cstring "/managing")

  result = buildHtml(tdiv()):
    listmenu(linfo.menu)

    if route == "#/profile":
      genericPage("This is profile page")
    elif route == "#/statistics":
      genericPage("This is statistics page")
    elif route == "#/information":
      genericPage("This is information page")
    else:
      p: text fmt"Your login session id is {linfo.user.sessid}"

      button:
        text "Logout"
        proc onclick() =
          ajaxPut(cstring"/logout",
            [(cstring"content-type", cstring"application/json")],
            $(%* {"username": linfo.user.username,
                  "sessid": linfo.user.sessid }),
            logoutCb)

proc registerView: VNode =
  proc registerCb(status: int, response: cstring) =
    loggingIn = false
    if status >= Http400.int:
      authenticated = false
      revokeAuthentication()
      loginMessage = $response
    else:
      loginMessage = $response
      #loginInfo = ($response).parseJson.to LoginInfo
      echo loginMessage

  let userreg = kstring"ureg"
  let passreg = kstring"preg"
  result = buildHtml(tdiv()):
    tdiv:
      label(`for` = userreg): text "Username for register"
      input(class = kstring"input", id = userreg, `type`=kstring"text")
    tdiv:
      label(`for` = passreg): text "Password for login"
      input(class = kstring"password", id = passreg, `type`=kstring"password")
    tdiv:
      label(`for` = kstring"inforeg"): text "Email user"
      input(class = kstring"email", id = kstring"inforeg", `type`=kstring"email")
    button:
      text "Register"
      proc onclick() =
        let
          #passnode = getVNodeById(passreg)
          #unamenode = getVNodeById(userreg)
          passnode = document.getElementById(passreg)
          unamenode = document.getElementById(userreg)
        register = false
        {.emit: "console.log(`passnode`);".}
        if passnode.value != "" or unamenode.value != "":
          echo "we can reach this, nice"
          ajaxPost(cstring"/register",
            [(cstring"content-type", cstring"application/json")],
            $(%* {"username": $unamenode.value, "password": $passnode.value }),
            registerCb)


proc loginDialog(data: RouterData): VNode =
  proc loginCb(status: int, response: cstring) =
    loggingIn = false
    if status >= Http400.int:
      authenticated = false
      revokeAuthentication()
      loginMessage = $response
    else:
      loginMessage = "login success"
      authenticated = true
      setAuthenticated()
      loginInfo = ($response).parseJson.to LoginInfo
      #"location".toJs.href = "#/user"
      setItem("loginInfo", response)
      echo loginInfo
      timer = setTimeout((proc() =
        authenticated = false
        revokeAuthentication()
        ), 1000 * 60)

  var loginpage = buildHtml tdiv:
    if not authenticated:
      p: text loginMessage
    loginField("Username", username, "input", validateNotEmpty)
    loginFIeld("Password", password, "password", validateNotEmpty, "password")
    span:
      button(disabled = disableOnError(), style = style((margin, kstring"5px"))):
        text "Login"
        proc onclick() =
          let
            uname = getVNodeById(username).text
            pass = getVNodeById(password).text
          loggingIn = true
          ajaxPost(cstring"/login",
            [(cstring"content-type", cstring"application/json")],
            $(%* {"username": $uname, "password": $pass }),
            loginCb)
      button(style = style((margin, kstring"5px"))):
        text "Register"
        proc onclick() = register = true
    p: text $getError(username)
    p: text $getError(password)

  var loggingPage = buildHtml tdiv:
    p: text "You're logging in, waiting for authentication"

  echo data.hashPart
  if loggingIn:
    result = buildHtml tdiv:
      p: text "You're logging in, waiting for authentication"
  elif register:
    result = registerView()
    #result = registerPage
  elif authenticated or data.hashPart == "#/user":
    result = loggedIn(loginInfo, data.hashPart)
  else:
    result = loginpage

setError(username, username & " must be not empty")
setError(password, password & " must be not empty")

setRenderer loginDialog
