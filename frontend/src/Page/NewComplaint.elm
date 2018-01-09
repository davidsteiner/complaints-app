module Page.NewComplaint exposing (ExternalMsg(..), initialModel, Model, Msg, update, view)

import Data.Conversation exposing (Complaint)
import Data.User exposing (Session, User)
import Html exposing (a, button, div, form, Html, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onSubmit)
import Http
import Jwt exposing (JwtError(..))
import Request.Complaint
import Request.Helpers exposing (send)
import Route
import Util exposing ((=>))
import Views.Input exposing (viewTextField, viewTextArea)


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
    }


type ExternalMsg
    = NoOp
    | ErrorReceived JwtError


initialModel : User -> Model
initialModel user =
    { serverError = Nothing, subject = "", message = "", user = user }


view : Session -> Model -> Html Msg
view _ model =
    form [ class "form-group", onSubmit SubmitForm ]
        [ viewTextField { id = "subject-input", label = "Tárgy", value = model.subject, msg = SetSubject }
        , viewTextArea { label_ = "Észrevétel", val = model.message, msg = SetMessage }
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
            case validate model of
                [] ->
                    model => send model.user ComplaintRegistered (Request.Complaint.newComplaint model) => NoOp

                errors ->
                    model => Cmd.none => NoOp

        SetSubject s ->
            { model | subject = s } => Cmd.none => NoOp

        SetMessage msg ->
            { model | message = msg } => Cmd.none => NoOp

        ComplaintRegistered (Err err) ->
            case err of
                TokenExpired ->
                    model => Route.modifyUrl Route.Logout => NoOp

                otherError ->
                    model => Cmd.none => ErrorReceived otherError

        ComplaintRegistered (Ok complaint) ->
            model => Route.modifyUrl (Route.Conversation complaint.id) => NoOp


validate : Model -> List Error
validate model =
    []
