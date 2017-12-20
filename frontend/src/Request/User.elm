module Request.User exposing (login, register, storeSession)

import Http
import Json.Decode as Decode
import Json.Encode as Encode

import Data.User as User exposing (User)
import Request.Helpers exposing (apiUrl)
import Ports


storeSession : User -> Cmd msg
storeSession user =
  User.encode user
    |> Encode.encode 0
    |> Just
    |> Ports.storeSession


login : { r | username: String, password : String } -> Http.Request User
login { username, password } =
  let
      user =
        Encode.object
          [ ( "username", Encode.string username )
          , ( "password", Encode.string password )
          ]

      body =
        Http.jsonBody user
  in
  Decode.field "user" User.decoder
    |> Http.post (apiUrl "/api-token-auth/") body


register : { r | username: String, password: String, email: String, firstName: String } -> Http.Request User
register { username, password, email, firstName } =
  let
      user = 
        Encode.object
          [ ( "username", Encode.string username )
          , ( "password", Encode.string password )
          , ( "email", Encode.string email)
          , ( "firstName", Encode.string firstName )
          ] |> Debug.log "Registering"
      body =
        Http.jsonBody user
  in
  Decode.field "user" User.decoder
    |> Http.post (apiUrl "/register/") body
