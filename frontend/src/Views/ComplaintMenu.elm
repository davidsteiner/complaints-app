module Views.ComplaintMenu exposing (..)

import Data.Conversation exposing (Complaint)
import Data.User exposing (User)
import Html exposing (a, Attribute, div, hr, Html, i, input, label, li, node, p, span, text, ul)
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


viewMenu : User -> List Complaint -> Html msg
viewMenu user complaints =
    let
        btn =
            if user.isStaff then
                [ text "" ]
            else
                [ newComplaintButton, hr [] [] ]
    in
        aside
            [ class "menu" ]
            [ div [] btn
            , p [ class "menu-label" ] [ text "Észrevételek" ]
            , viewComplaints complaints
            ]


newComplaintButton : Html msg
newComplaintButton =
    a [ class "button is-dark is-outlined is-block is-alt is-large", href NewComplaint ]
        [ text "Új észrevétel" ]


viewComplaint : Complaint -> Html msg
viewComplaint complaint =
    li []
        [ a [ class "button is-outlined is-fullwidth", href (Conversation complaint.id) ]
            [ span [ class "icon" ] [ i [ class "fa fa-book" ] [] ]
            , span [] [ text complaint.subject ]
            ]
        ]


viewComplaints : List Complaint -> Html msg
viewComplaints complaints =
    complaints
        |> List.map viewComplaint
        |> ul []


init : User -> Http.Request (List Complaint)
init user =
    complaintList user
