module Page.Home exposing (view)

import Html exposing (a, Html, div, text)
import Html.Attributes exposing (class)
import Data.User exposing (Session, usernameToString)
import Route exposing (href)
import Views.ComplaintMenu exposing (viewMenu)


view : Session -> Html msg
view session =
    case session of
        Nothing ->
            div []
                [ text "Welcome, you are not logged in."
                , div [] [ a [ href Route.Login ] [ text "Login Here" ] ]
                ]

        Just user ->
            div []
                [ text "Home screen"
                ]
