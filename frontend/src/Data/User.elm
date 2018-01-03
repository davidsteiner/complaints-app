module Data.User exposing (Session, User, Username, usernameToString, usernameParser, decoder, encode, withAuthorisation)

import HttpBuilder exposing (RequestBuilder, withHeader)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, optional, required)
import Json.Encode as Encode exposing (Value)
import UrlParser


type alias User =
    { username : Username
    , email : String
    , token : AuthToken
    }


type alias Session =
    Maybe User


type Username
    = Username String


type AuthToken
    = AuthToken String


decoder : Decoder User
decoder =
    decode User
        |> required "username" usernameDecoder
        |> required "email" Decode.string
        -- This is optional as the registration page shares this code. TODO: make this nicer
        |> optional "token" tokenDecoder (AuthToken "")


encode : User -> Value
encode user =
    Encode.object
        [ ( "username", encodeUsername user.username )
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
