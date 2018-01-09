module Page.Conversation exposing (ExternalMsg(..), init, initialModel, Model, Msg, update, view)

import Data.Conversation exposing (ConversationMessage)
import Data.User exposing (Session, User)
import Html exposing (a, br, button, div, form, hr, Html, p, section, small, span, strong, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onSubmit)
import Http
import Jwt exposing (JwtError(..))
import Request.Complaint exposing (conversation)
import Request.Helpers exposing (send)
import Route exposing (href)
import Task exposing (Task)
import Views.Input exposing (viewTextArea)


type alias Model =
    { conversation : Data.Conversation.Conversation
    , newMessage : String
    , user : User
    }


type alias Error =
    Maybe String


type Msg
    = SetMessage String
    | SubmitForm
    | MessageSent (Result JwtError Data.Conversation.Conversation)


type ExternalMsg
    = NoOp
    | ErrorReceived JwtError


initialModel : Data.Conversation.Conversation -> User -> Model
initialModel conversation user =
    { conversation = conversation, newMessage = "", user = user }


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
    a [ class "button is-primary is-pulled-right is-hidden-desktop", href Route.Home ] [ text "Vissza" ]


viewMessages : User -> List ConversationMessage -> Html Msg
viewMessages user messages =
    let
        msgContents =
            List.intersperse
                (hr [] [])
                (messages
                    |> List.reverse
                    |> List.map (viewMessage user)
                )
    in
        div [ class "message" ]
            [ div [ class "message-body" ] msgContents ]


viewMessage : User -> ConversationMessage -> Html msg
viewMessage user message =
    div []
        [ div [ class "is-pulled-right" ] [ strong [] [ text message.sender ], small [] [ text (" - " ++ message.created) ] ]
        , br [] []
        , div [ class "content", style [ ( "white-space", "pre-wrap" ) ] ] [ text message.text ]
        ]


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SubmitForm ->
            case validate model of
                [] ->
                    ( ( model, (send model.user MessageSent (Request.Complaint.sendMessage model.user model.newMessage model.conversation.complaint.id)) )
                    , NoOp
                    )

                errors ->
                    ( ( model, Cmd.none ), NoOp )

        SetMessage msg ->
            ( ( { model | newMessage = msg }, Cmd.none ), NoOp )

        MessageSent (Err err) ->
            case err of
                TokenExpired ->
                    ( ( model, Route.modifyUrl Route.Logout ), NoOp )

                otherError ->
                    ( ( model, Cmd.none ), ErrorReceived otherError )

        MessageSent (Ok conversation) ->
            ( ( { model | conversation = conversation, newMessage = "" }, Cmd.none )
            , NoOp
            )


init : User -> Int -> Http.Request Data.Conversation.Conversation
init user complaintId =
    conversation user complaintId


validate : Model -> List String
validate model =
    []
