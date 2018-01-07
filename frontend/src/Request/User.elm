module Request.User exposing (login, refreshToken, register, storeSession)

import Http
import HttpBuilder exposing (RequestBuilder, post, toRequest, withBody, withExpect)
import Json.Decode as Decode
import Json.Encode as Encode
import Data.User as User exposing (AuthToken, encodeToken, Session, User, Username, withAuthorisation)
import Request.Helpers exposing (apiUrl)
import Ports


storeSession : Session -> Cmd msg
storeSession session =
    case session of
        Just user ->
            User.encode user
                |> Encode.encode 0
                |> Just
                |> Ports.storeSession

        Nothing ->
            Ports.storeSession Nothing


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

        body =
            Http.jsonBody user
    in
        Decode.field "username" User.usernameDecoder
            |> Http.post (apiUrl "/register/") body


refreshToken : AuthToken -> Http.Request AuthToken
refreshToken token =
    let
        body =
            Encode.object
                [ ( "token", encodeToken token ) ]
                |> Http.jsonBody

        decoder =
            Decode.field "token" User.tokenDecoder
    in
        apiUrl "/api-token-refresh/"
            |> post
            |> withBody body
            |> withExpect (Http.expectJson decoder)
            |> toRequest
