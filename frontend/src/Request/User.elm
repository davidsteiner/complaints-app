module Request.User exposing (login, register, storeSession)

import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Data.User as User exposing (User, Username)
import Request.Helpers exposing (apiUrl)
import Ports


storeSession : User -> Cmd msg
storeSession user =
    User.encode user
        |> Encode.encode 0
        |> Just
        |> Ports.storeSession


login : { r | username : String, password : String } -> Http.Request User.AuthToken
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
        Decode.field "token" User.tokenDecoder
            |> Http.post (apiUrl "/api-token-auth/") body


register : { r | username : String, password : String, email : String } -> Http.Request Username
register { username, password, email } =
    let
        user =
            Encode.object
                [ ( "username", Encode.string username )
                , ( "password", Encode.string password )
                , ( "email", Encode.string email )
                ]
                |> Debug.log "Registering"

        body =
            Http.jsonBody user
    in
        Decode.field "username" User.usernameDecoder
            |> Http.post (apiUrl "/register/") body
