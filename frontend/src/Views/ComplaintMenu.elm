module Views.ComplaintMenu exposing (..)

import Data.Conversation exposing (Complaint)
import Data.User exposing (User)
import Html exposing (a, Attribute, div, Html, input, label, li, node, p, text, ul)
import Html.Attributes exposing (class, id, type_, value)
import Html.Events exposing (onInput)
import Http
import Request.Complaint exposing (complaintList)
import Route exposing (href, Route(Conversation, NewComplaint))
import Task exposing (Task)


type alias Model =
    List { conversationId : String, subject : String }


aside : List (Attribute msg) -> List (Html msg) -> Html msg
aside attributes children =
    node "aside" attributes children


viewMenu : List Complaint -> Html msg
viewMenu complaints =
    div [ class "column is-3" ]
        [ aside
            [ class "menu" ]
            [ newComplaintButton
            , p [ class "menu-label" ] [ text "Complaints" ]
            , viewComplaints complaints
            ]
        ]


newComplaintButton : Html msg
newComplaintButton =
    a [ class "button is-warning is-block is-alt is-large", href NewComplaint ]
        [ text "Panasz" ]


viewComplaint : Complaint -> Html msg
viewComplaint complaint =
    li [] [ a [ href (Conversation complaint.id) ] [ text complaint.subject ] ]


viewComplaints : List Complaint -> Html msg
viewComplaints complaints =
    complaints
        |> List.map viewComplaint
        |> ul []


init : User -> Task Http.Error (List Complaint)
init user =
    complaintList user
        |> Http.toTask
