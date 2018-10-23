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

type
  PersonInfo = object
    id*: int
    name*: string
    age*: int

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
            except:newseq[string]()
    if row.len == 0 or row.allIt( it == ""):
      resp(Http404, msgjson(fmt"id {id} not found"),
        contentType="application/json")
    else:
      echo row
      resp(Http200, $(%*{
        "id": id,
        "name": row[1],
        "age": row[2]
        }), contentType = "application/json")

  get "/info":
    let page =
      try:
        if "page" in request.params: request.params["page"].parseInt
        else: 1
      except: 1
    let limit =
      try:
        if "limit" in request.params: request.params["limit"].parseInt
        else: 5
      except: 5
    let row = try:
                db.getAllRows(sql"SELECT * FROM person_info LIMIT ? OFFSET ?;",
                  limit, (page-1) * limit)
              except: newseq[Row]()

    if row.len == 0:
      resp(Http500, msgjson("Cannot fetch person info"),
        contentType = "application/json")
    else:
      var people = newseq[PersonInfo]()
      for r in row:
        people.add PersonInfo(id: r[0].parseInt, name: r[1], age: r[2].parseInt)

      resp(Http200, $(%*people))

  post "/register":
    let body = try: request.body.parseJson
               except: newJNull()
    if body.kind == JNull:
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
