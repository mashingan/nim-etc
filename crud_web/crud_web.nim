import db_sqlite, asyncdispatch, json, strformat, strutils, sequtils

import jester

var db = open("person.db", "", "", "person")

# exec can raise exception, in this case we let it crash because this
# is just configuration
db.exec(sql"""
CREATE TABLE IF NOT EXISTS person_info(
  id INTEGER PRIMARY KEY,
  name VARCHAR(20) NOT NULL,
  age INTEGER)""")

proc msgjson(msg: string): string =
  """{"msg": $#}""" % [msg]

settings:
  port = Port 3000

routes:
  get "/info/@id":
    let
      id = try: parseInt(@"id")
           except ValueError: -1
    if id == -1:
      resp(Http400, msgjson("Invalid id format"), contentType = "application/json")
    let
      row = try:
              db.getRow(sql"SELECT * FROM person_info WHERE id=?", id)
            except:nil
    if row.isNil or row.all(proc(x: string): bool = x.isNil or x == ""):
      # why cannot row.all(isNil) :/
      resp(Http404, msgjson(fmt"id {id} not found"),
        contentType="application/json")
    else:
      echo row
      resp(Http200, $(%*{
        "id": id,
        "name": row[1],
        "age": row[2]
        }), contentType = "application/json")

  post "/register":
    let body = try: request.body.parseJson
               except: newJNull()
    if body.isNil:
      resp(Http400, msgjson("Invalid json"),
        contentType="application/json")
    try:
      db.exec(sql"""
        INSERT INTO person_info(name, age)
        VALUES (?, ?);""",
        body["name"].getStr, body["age"].getInt)
      var id = db.getRow(sql"SELECT LAST_INSERT_ROWID();")[0].parseInt
      resp(Http200, $(%*{"id": id}) , contentType="application/json")
    except:
      resp(Http500, msgjson("something happened"), contentType="application/json")

runForever()
