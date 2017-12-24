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


stateToClass : State -> String
stateToClass state =
    if state then
        "is-active"
    else
        ""


viewNavbar : State -> Bool -> List Complaint -> Html Msg
viewNavbar state isLoading complaints =
    -- TODO: display spinner when it isLoading
    nav [ class "navbar is-dark", attribute "role" "navigation", style [ ( "margin-bottom", "20px" ) ] ]
        [ navbarBrand state
        , navbarMenu state complaints
        ]


navbarMenu : State -> List Complaint -> Html Msg
navbarMenu state complaints =
    div [ class ("navbar-menu " ++ stateToClass state), id "navMenu" ]
        [ navbarStart
        , navbarEnd complaints
        ]


navbarStart : Html Msg
navbarStart =
    div [ class "navbar-start" ]
        []


navbarEnd : List Complaint -> Html Msg
navbarEnd complaints =
    div [ class "navbar-end" ]
        ([ logoutLink
         , hr [ class "navbar-divider" ] []
         , div [ class "navbar-item is-hidden-desktop menu-label" ] [ text "Panaszok:" ]
         ]
            ++ navbarComplaints complaints
        )


logoutLink : Html Msg
logoutLink =
    a [ class "navbar-item", href Route.Logout ]
        [ span [ class "icon" ] [ i [ class "fa fa-sign-out" ] [] ] ]


homeLink : Html Msg
homeLink =
    a [ class "navbar-item", href Route.Home ]
        [ span [ class "icon" ] [ i [ class "fa fa-home" ] [] ] ]


navbarComplaints : List Complaint -> List (Html Msg)
navbarComplaints complaints =
    complaints
        |> List.map (\c -> navbarLinkTouch (Route.Conversation c.id) c.subject)


navbarBrand : State -> Html Msg
navbarBrand state =
    div [ class "navbar-brand" ]
        [ homeLink
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


navbarLinkTouch : Route -> String -> Html Msg
navbarLinkTouch route label =
    a [ class "navbar-item is-hidden-desktop", href route ] [ text label ]
