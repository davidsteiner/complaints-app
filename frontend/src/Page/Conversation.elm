module Page.Conversation exposing (..)

import Data.Conversation exposing (ConversationMessage)
import Data.User exposing (Session, User, usernameToString)
import Html exposing (a, br, button, div, form, h2, hr, Html, li, ol, p, section, small, span, strong, text, textarea, ul)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onSubmit)
import Http
import Request.Complaint exposing (conversation)
import Route exposing (href)
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
    case session of
        Just user ->
            div [ class "" ]
                [ viewSubjectHero (model.conversation.complaint.subject)
                , viewMessageTextArea model
                , viewMessages user model.conversation.messages
                ]

        Nothing ->
            div [] []


viewSubjectHero : String -> Html Msg
viewSubjectHero subject =
    section [ class "hero is-dark welcome is-small" ]
        [ div [ class "hero-body" ]
            [ span [ class "title" ] [ text subject ]
            , backToHomeButton
            ]
        ]


viewMessageTextArea : Model -> Html Msg
viewMessageTextArea model =
    form [ class "form-group", onSubmit SubmitForm, style [ ( "margin-bottom", "20px" ) ] ]
        [ viewTextArea { label_ = "", val = model.newMessage, msg = SetMessage }
        , submitButton
        ]


submitButton : Html Msg
submitButton =
    div [ class "field" ]
        [ p [ class "control" ]
            [ button [ class "button is-primary" ] [ text "Válasz" ] ]
        ]


backToHomeButton : Html Msg
backToHomeButton =
    a [ class "button is-primary is-pulled-right", href Route.Home ] [ text "Vissza" ]


viewMessages : User -> List ConversationMessage -> Html Msg
viewMessages user messages =
    let
        msgContents =
            List.intersperse
                (hr [] [])
                (messages
                    |> List.map (viewMessage user)
                )
    in
        div [ class "message" ]
            [ div [ class "message-body" ] msgContents ]


viewMessage : User -> ConversationMessage -> Html msg
viewMessage user message =
    div []
        [ strong [] [ text message.sender ]
        , small [] [ text message.created ]
        , br [] []
        , text message.text
        ]


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
