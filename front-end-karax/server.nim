import jester, asynchttpserver, json, strformat, tables, strutils
import htmlgen, sequtils
from os import sleep

import types

settings:
  port = Port 3000
  staticDir = "./pkgs"

var
  users = newStringTable("dummy", "dummy", modeCaseSensitive)
  session = newTable[int, User]()
  logins = newTable[string, bool]()
  counts = 0
  #menu = @["profil", "statistics", "information"]
  menu = [("profile", "#/profile"),
    ("statistics", "#/statistics"),
    ("information", "#/information")].mapIt(
      Menu(label: it[0], href: it[1]))

routes:
  get "/managing":
    const loginpage = staticRead "pkgs/app.html"
    resp loginpage

  put "/logout":
    var userjson = try: request.body.parseJson
                   except: newJNull()
    if userjson.kind == JNull:
      resp(Http400, "Invalid request")

    let user = if "sessid" in userjson: session[userjson["sessid"].getInt()]
               else: User()

    if user.username == "":
      resp(Http404, "User not found")

    let
      sessid = userjson["sessid"].getInt

    session.del sessid
    logins[user.username] = false
    resp(Http200, fmt"{user.username} successfully logout")

  post "/login":
    var user = request.body.parseJson.to User
    echo fmt"logging-in {user.username} with password {user.password}"
    sleep 1000 #simulating network congestion
    if user.username notin users:
      resp(Http404, fmt"there's no such user {user.username}")
    else:
      if user.password != users[user.username]:
        resp(Http401, "Invalid password")
      else:
        var sessid: int
        var resobj = %*{
          "menu": menu,
          "user": {
            "username": user.username,
            "sessid": -1,
          }
        }
        if user.username in logins and logins[user.username]:
          for count, u in session:
            if u.username == user.username:
              sessid = count
              resobj["user"]["sessid"] = sessid.newJInt
              break
          resp(Http201, $resobj, contentType = "application/json")
        else:
          inc counts
          session[counts] = user
          logins[user.username] = true
          resobj["user"]["sessid"] = counts.newJInt
          resp(Http201, $resobj, contentType = "application/json")

  post "/register":
    let user = try: request.body.parseJson.to User
               except: User()
    if user.username == "":
      resp(Http400, "Invalid request form")
    elif user.username in users:
      resp(Http401, "Already registered, please login instead")

    users[user.username] = user.password
    resp(Http201, fmt"{user.username} registered, please login")

  get "/":
    let uname = if "username" in request.params: request.params["username"]
                else: ""
    if uname == "" or not logins[uname]:
      resp(Http302, [
        ("location", "/restricted")
        ], "Restricted")

  get "/restricted":
    resp(Http404, html(
      h1(em("RESTRICTED")),
      hr()))
