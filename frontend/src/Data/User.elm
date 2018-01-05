module Data.User exposing (AuthToken(..), Session, User, Username, tokenToUser, tokenToString, usernameToString, usernameParser, usernameDecoder, tokenDecoder, decoder, encode, withAuthorisation)

import HttpBuilder exposing (RequestBuilder, withHeader)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, optional, required)
import Json.Encode as Encode exposing (Value)
import Jwt exposing (decodeToken)
import UrlParser


type alias User =
    { username : Username
    , exp : Int
    , token : AuthToken
    }


type alias Session =
    Maybe User


type Username
    = Username String


type AuthToken
    = AuthToken String


tokenToUser : AuthToken -> Maybe User
tokenToUser ((AuthToken tokenStr) as token) =
    case decodeToken decoder tokenStr of
        Err _ ->
            Nothing

        Ok user ->
            Just { user | token = token }


decoder : Decoder User
decoder =
    decode User
        |> required "username" usernameDecoder
        |> required "exp" Decode.int
        |> optional "token" tokenDecoder (AuthToken "")


encode : User -> Value
encode user =
    Encode.object
        [ ( "username", encodeUsername user.username )
        , ( "exp", Encode.int user.exp )
        , ( "token", encodeToken user.token )
        ]


usernameToString : Username -> String
usernameToString (Username name) =
    name


usernameDecoder : Decoder Username
usernameDecoder =
    Decode.map Username Decode.string


usernameParser : UrlParser.Parser (Username -> a) a
usernameParser =
    UrlParser.custom "USERNAME" (Ok << Username)


encodeUsername : Username -> Value
encodeUsername (Username name) =
    Encode.string name


tokenToString : AuthToken -> String
tokenToString (AuthToken token) =
    token


tokenDecoder : Decoder AuthToken
tokenDecoder =
    Decode.map AuthToken Decode.string


encodeToken : AuthToken -> Value
encodeToken (AuthToken token) =
    Encode.string token


withAuthorisation : AuthToken -> RequestBuilder a -> RequestBuilder a
withAuthorisation (AuthToken token) builder =
    builder
        |> withHeader "Authorization" ("JWT " ++ token)
