module Page.Errored exposing (ErrorMessage, view)

import Html exposing (div, Html, text)
import Html.Attributes exposing (class)
import Http exposing (Error(..))
import Jwt exposing (JwtError(..))


type alias ErrorMessage =
    JwtError


view : ErrorMessage -> Html msg
view errorMessage =
    div [ class "message is-danger" ]
        [ div [ class "message-header" ] [ text "Error" ]
        , div [ class "message-body" ] [ text <| formatError errorMessage ]
        ]


formatError : JwtError -> String
formatError err =
    case err of
        TokenExpired ->
            "Token has expired."

        HttpError httpError ->
            formatHttpError httpError

        Unauthorized ->
            "Unauthorized request to resource."

        TokenNotExpired ->
            "Unexpected token error."

        TokenProcessingError errorString ->
            "Error in processing token: " ++ errorString

        TokenDecodeError errorString ->
            "Error in decoding token: " ++ errorString


formatHttpError : Error -> String
formatHttpError err =
    case err of
        Timeout ->
            "Timeout error."

        NetworkError ->
            "Unexpected network error."

        BadPayload payload _ ->
            "Incorrect/unexpected payload: " ++ payload

        BadStatus response ->
            "Bad response from server (" ++ toString response.status.code ++ "): " ++ response.status.message

        BadUrl error ->
            "Bad URL error: " ++ error
