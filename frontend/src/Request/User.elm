module Request.User exposing (login, refreshTokenCmd, register, storeSession)

import Http
import HttpBuilder exposing (RequestBuilder, post, toRequest, withBody, withExpect)
import Json.Decode as Decode
import Json.Encode as Encode
import Jwt exposing (handleError, JwtError)
import Data.User as User exposing (AuthToken(AuthToken), encodeToken, Session, User, Username)
import Request.Helpers exposing (apiUrl)
import Ports
import Task exposing (Task)
import Time


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


register : { r | username : String, password : String, email : String, registrationToken : String } -> Http.Request Username
register { username, password, email, registrationToken } =
    let
        user =
            Encode.object
                [ ( "username", Encode.string username )
                , ( "password", Encode.string password )
                , ( "email", Encode.string email )
                , ( "regtoken", Encode.string registrationToken )
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


refreshTokenCmd : User -> (Result JwtError AuthToken -> msg) -> Cmd msg
refreshTokenCmd user msgCreator =
    let
        getCmd : Float -> Task Never (Result JwtError AuthToken)
        getCmd remainingLife =
            if remainingLife < 30 * 60 * 1000 then
                refreshToken user.token
                    |> Http.toTask
                    |> Task.map Result.Ok
                    |> Task.onError (Task.map Err << handleError (User.tokenToString user.token))
            else
                Task.succeed (Ok user.token)
    in
        tokenRemainingLife user.exp
            |> Task.andThen getCmd
            |> Task.perform msgCreator


tokenRemainingLife : Int -> Task Never Float
tokenRemainingLife expires =
    Time.now
        |> Task.andThen ((-) (toFloat expires * 1000) >> Task.succeed)
