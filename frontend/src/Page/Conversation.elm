module Page.Conversation exposing (..)

import Data.Conversation exposing (ConversationMessage)
import Data.User exposing (Session, User)
import Html exposing (div, Html, li, text, ul)
import Http
import Request.Complaint exposing (conversation)
import Task exposing (Task)


type alias Model =
    Data.Conversation.Conversation


view : Session -> Model -> Html msg
view session model =
    div []
        [ text (model.complaint.subject)
        , viewMessages model.messages
        ]


viewMessages : List ConversationMessage -> Html msg
viewMessages messages =
    messages
        |> List.map viewMessage
        |> ul []


viewMessage : ConversationMessage -> Html msg
viewMessage message =
    li [] [ text message.text ]


init : User -> Int -> Task Http.Error Model
init user complaintId =
    conversation user complaintId
        |> Http.toTask
