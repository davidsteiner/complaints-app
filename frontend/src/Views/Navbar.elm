module Views.Navbar exposing (Msg, State, viewNavbar)

import Html exposing (a, button, div, Html, nav, span, text)
import Html.Attributes exposing (attribute, class, id, style)
import Html.Events exposing (onClick)
import Data.User exposing (User, usernameToString)
import Route exposing (href, Route)


type alias State =
    Bool


type Msg
    = ToggleBurger


stateToClass : State -> String
stateToClass state =
    if state then
        "is-active"
    else
        ""


viewNavbar : User -> State -> Bool -> Html Msg
viewNavbar user state isLoading =
    nav [ class "navbar is-dark", attribute "role" "navigation", style [ ( "margin-bottom", "20px" ) ] ]
        [ navbarBrand state
        , navbarMenu user state
        ]


navbarMenu : User -> State -> Html Msg
navbarMenu user state =
    div [ class ("navbar-menu " ++ stateToClass state), id "navMenu" ]
        [ navbarStart
        , navbarEnd user
        ]


navbarStart : Html Msg
navbarStart =
    div [ class "navbar-start" ]
        []


navbarEnd : User -> Html Msg
navbarEnd user =
    div [ class "navbar-end" ]
        [ div [ class "navbar-item" ] [ text ("Hello, " ++ usernameToString user.username) ]
        , navbarLink Route.Logout "Logout"
        ]


navbarBrand : State -> Html Msg
navbarBrand state =
    div [ class "navbar-brand" ]
        [ navbarLink Route.Home "Home"
        , navbarBurger state
        ]


navbarBurger : State -> Html Msg
navbarBurger state =
    button [ class ("button navbar-burger burger is-dark " ++ stateToClass state), attribute "data-target" "navMenu", onClick ToggleBurger ]
        [ span [] []
        , span [] []
        , span [] []
        ]


navbarLink : Route -> String -> Html Msg
navbarLink route label =
    a [ class "navbar-item", href route ] [ text label ]
