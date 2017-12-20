module Views.ComplaintMenu exposing (..)

import Data.Conversation exposing (Conversation)
import Html exposing (a, Attribute, div, Html, input, label, li, node, p, text, ul)
import Html.Attributes exposing (class, id, type_, value)
import Html.Events exposing (onInput)
import Route exposing (href, Route(NewComplaint))


type alias Model =
    List { conversationId : String, subject : String }


aside : List (Attribute msg) -> List (Html msg) -> Html msg
aside attributes children =
    node "aside" attributes children


viewMenu : List Conversation -> Html msg
viewMenu convos =
    div [ class "column is-3" ]
        [ aside
            [ class "menu" ]
            [ newComplaintButton
            , p [ class "menu-label" ] [ text "Complaints" ]
            , viewConversations convos
            ]
        ]


newComplaintButton : Html msg
newComplaintButton =
    a [ class "button is-warning is-block is-alt is-large", href NewComplaint ]
        [ text "Panasz" ]


viewConversation : Conversation -> Html msg
viewConversation convo =
    li [] [ a [] [ text "Sample Conv" ] ]


viewConversations : List Conversation -> Html msg
viewConversations convos =
    convos
        |> List.map viewConversation
        |> ul []
