type
  LoginInfo* = object
    user*: UserInfo
    menu*: seq[Menu]

  UserInfo* = object
    username*: string
    sessid*: int

  Menu* = object
    label*, href*: string

  User* = object
    username*, password*: string
