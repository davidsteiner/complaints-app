module Page.Conversation exposing (..)

import Data.Conversation exposing (ConversationMessage)
import Data.User exposing (Session, User)
import Html exposing (button, div, form, Html, li, p, text, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onSubmit)
import Http
import Request.Complaint exposing (conversation)
import Task exposing (Task)
import Views.Input exposing (viewTextArea)


type alias Model =
    { conversation : Data.Conversation.Conversation
    , newMessage : String
    , errors : List String
    , user : User
    }


type Msg
    = SetMessage String
    | SubmitForm
    | MessageSent (Result Http.Error Data.Conversation.Conversation)


type ExternalMsg
    = NoOp


initialModel : Data.Conversation.Conversation -> User -> Model
initialModel conversation user =
    { conversation = conversation, newMessage = "", errors = [], user = user }


view : Session -> Model -> Html Msg
view session model =
    div []
        [ viewMessageTextArea session model
        , text (model.conversation.complaint.subject)
        , viewMessages model.conversation.messages
        ]


viewMessageTextArea : Session -> Model -> Html Msg
viewMessageTextArea _ model =
    form [ class "form-group", onSubmit SubmitForm ]
        [ viewTextArea { label_ = "", val = model.newMessage, msg = SetMessage }
        , submitButton
        ]


submitButton : Html Msg
submitButton =
    div [ class "field" ]
        [ p [ class "control" ]
            [ button [ class "button is-primary" ] [ text "Kuldes" ] ]
        ]


viewMessages : List ConversationMessage -> Html Msg
viewMessages messages =
    messages
        |> List.map viewMessage
        |> ul []


viewMessage : ConversationMessage -> Html msg
viewMessage message =
    li [] [ text (message.sender ++ ": " ++ message.text) ]


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        -- Login request is submitted
        SubmitForm ->
            case validate model of
                [] ->
                    ( ( { model | errors = [] }, (Http.send MessageSent (Request.Complaint.sendMessage model.user model.newMessage model.conversation.complaint.id)) )
                    , NoOp
                    )

                errors ->
                    ( ( { model | errors = errors }, Cmd.none ), NoOp )

        SetMessage msg ->
            ( ( { model | newMessage = msg }, Cmd.none ), NoOp )

        MessageSent (Err error) ->
            let
                errorMessages =
                    case error of
                        Http.BadStatus response ->
                            [ (response.body |> Debug.log "bad response") ]

                        _ ->
                            [ ("Unable to process complaint. Reason: " ++ (toString error)) |> Debug.log "undefined resp" ]
            in
                ( ( { model | errors = errorMessages }
                  , Cmd.none
                  )
                , NoOp
                )

        -- Login succeeded
        MessageSent (Ok conversation) ->
            ( ( { model | conversation = conversation, newMessage = "" }, Cmd.none )
            , NoOp
            )


init : User -> Int -> Task Http.Error Data.Conversation.Conversation
init user complaintId =
    conversation user complaintId
        |> Http.toTask


validate : Model -> List String
validate model =
    []
