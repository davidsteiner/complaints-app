module Page.Conversation exposing (..)

import Data.Conversation
import Data.User exposing (Session, User)
import Html exposing (div, Html, text)
import Http
import Request.Complaint exposing (conversation)
import Task exposing (Task)


type alias Model =
    Data.Conversation.Conversation


view : Session -> Model -> Html msg
view session model =
    div [] [ text (toString model.complaint.id) ]


init : User -> Int -> Task Http.Error Model
init user complaintId =
    conversation user complaintId
        |> Http.toTask
