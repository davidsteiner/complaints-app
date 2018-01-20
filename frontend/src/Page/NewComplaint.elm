module Page.NewComplaint exposing (ExternalMsg(..), initialModel, Model, Msg, update, view)

import Data.Conversation exposing (Complaint)
import Data.User exposing (Session, User)
import Html exposing (a, button, div, form, Html, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onSubmit)
import Http
import Jwt exposing (JwtError(..))
import Maybe.Extra exposing (values)
import Request.Complaint
import Request.Helpers exposing (send)
import Route
import Util exposing ((=>))
import Views.Input exposing (InputError, viewTextField, viewTextArea)


type Msg
    = SubmitForm
    | SetSubject String
    | SetMessage String
    | ComplaintRegistered (Result JwtError Complaint)


type alias Error =
    Maybe String


type alias Model =
    { serverError : Error
    , subject : String
    , message : String
    , user : User
    , subjectError : InputError
    , messageError : InputError
    }


type ExternalMsg
    = NoOp
    | ErrorReceived JwtError


initialModel : User -> Model
initialModel user =
    { serverError = Nothing, subject = "", message = "", user = user, subjectError = Nothing, messageError = Nothing }


view : Session -> Model -> Html Msg
view _ model =
    form [ class "form-group", onSubmit SubmitForm ]
        [ viewTextField "Tárgy" model.subject SetSubject model.subjectError
        , viewTextArea "Észrevétel" model.message SetMessage model.messageError
        , div [ class "field is-grouped" ]
            [ div [ class "control" ] [ submitButton ]
            , div [ class "control" ] [ backToHomeButton ]
            ]
        ]


submitButton : Html Msg
submitButton =
    button [ class "button is-primary" ] [ text "Küldés" ]


backToHomeButton : Html Msg
backToHomeButton =
    a [ class "button is-danger is-pulled-right is-hidden-desktop", Route.href Route.Home ] [ text "Vissza" ]


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SubmitForm ->
            let
                validatedModel =
                    validate model

                cmd =
                    if hasErrors validatedModel then
                        Cmd.none
                    else
                        send model.user ComplaintRegistered (Request.Complaint.newComplaint model)
            in
                validatedModel => cmd => NoOp

        SetSubject s ->
            { model | subject = s, subjectError = Nothing } => Cmd.none => NoOp

        SetMessage msg ->
            { model | message = msg, messageError = Nothing } => Cmd.none => NoOp

        ComplaintRegistered (Err err) ->
            case err of
                TokenExpired ->
                    model => Route.modifyUrl Route.Logout => NoOp

                otherError ->
                    model => Cmd.none => ErrorReceived otherError

        ComplaintRegistered (Ok complaint) ->
            model => Route.modifyUrl (Route.Conversation complaint.id) => NoOp


hasErrors : Model -> Bool
hasErrors model =
    not <| List.isEmpty <| values [ model.subjectError, model.messageError ]


validate : Model -> Model
validate model =
    { model | subjectError = validateSubject model, messageError = validateMessage model }


validateSubject : Model -> InputError
validateSubject model =
    if String.isEmpty model.subject then
        Just "A tárgy mező nem lehet üres."
    else
        Nothing


validateMessage : Model -> InputError
validateMessage model =
    if String.isEmpty model.message then
        Just "Az üzenet nem lehet üres."
    else
        Nothing
