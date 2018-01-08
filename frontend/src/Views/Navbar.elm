module Views.Navbar exposing (Msg, State, viewNavbar)

import Data.Conversation exposing (Complaint)
import Html exposing (a, button, div, i, hr, Html, nav, span, text)
import Html.Attributes exposing (attribute, class, id, style)
import Html.Events exposing (onClick)
import Data.User exposing (User, usernameToString)
import Route exposing (href, Route)


type alias State =
    Bool


type Msg
    = ToggleBurger


viewNavbar : State -> Bool -> List Complaint -> Html Msg
viewNavbar state isLoading complaints =
    -- TODO: display spinner when it isLoading
    nav [ class "navbar is-dark", attribute "role" "navigation", style [ ( "margin-bottom", "20px" ) ] ]
        [ navbarBrand
        ]


logoutLink : Html Msg
logoutLink =
    a [ class "navbar-item", href Route.Logout ]
        [ span [ class "icon" ] [ i [ class "fa fa-sign-out" ] [] ]
        , text "Kijelentkezés"
        ]


homeLink : Html Msg
homeLink =
    a [ class "navbar-item is-hidden-touch", href Route.Home ]
        [ span [ class "icon" ] [ i [ class "fa fa-home" ] [] ]
        , text "Kezdőlap"
        ]


navbarBrand : Html Msg
navbarBrand =
    div [ class "navbar-brand" ]
        [ homeLink, logoutLink ]


navbarLink : Route -> String -> Html Msg
navbarLink route label =
    a [ class "navbar-item", href route ] [ text label ]


navbarLinkTouch : Route -> String -> Html Msg
navbarLinkTouch route label =
    a [ class "navbar-item is-hidden-desktop", href route ] [ text label ]
