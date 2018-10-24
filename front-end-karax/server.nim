import jester, asynchttpserver, json, strformat, tables, strutils
import htmlgen
from os import sleep

settings:
  port = Port 3000
  staticDir = "./nimcache"

type
  User = object
    username*, password*: string

var
  session = newTable[int, User]()
  logins = newTable[int, bool]()
  counts = 0
  menu = @["profil", "statistics", "information"]

routes:
  get "/managing":
    const loginpage = staticRead "nimcache/login_page.html"
    resp loginpage

  post "/login":
    var user = request.body.parseJson.to User
    echo fmt"logging-in {user.username} with password {user.password}"
    sleep 1000 #simulating network congestion
    if user.username != "dummy" or user.password != "dummy":
      resp(Http401, "Invalid username or password")
    else:
      inc counts
      session[counts] = user
      logins[counts] = true
      resp(Http201, $(%* {
        "menu": menu,
        "user": {
          "username": user.username,
          "sessid": counts
        }
      }), contentType = "application/json")

  get "/":
    let id = if "id" in request.params: request.params["id"].parseInt
             else: -1
    if id == -1 or not logins[id]:
      resp(Http302, [
        ("location", "/restricted")
        ], "Restricted")

  get "/restricted":
    resp(Http404, html(
      h1(em("RESTRICTED")),
      hr()))
