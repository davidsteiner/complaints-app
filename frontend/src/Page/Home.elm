module Page.Home exposing (Model, view)

import Html exposing (a, Html, div, text)
import Html.Attributes exposing (class)
import Data.Conversation exposing (Complaint)
import Data.User exposing (Session, usernameToString)
import Route exposing (href)
import Views.ComplaintMenu exposing (viewMenu)


type alias Model =
    List Complaint


view : Session -> List Complaint -> Html msg
view session complaints =
    case session of
        Nothing ->
            div [] []

        Just user ->
            div []
                [ div [ class "is-hidden-desktop" ] [ viewMenu complaints ]
                , div [ class "is-hidden-touch" ] [ text "Home screen" ]
                ]
