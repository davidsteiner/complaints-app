module Page.NewComplaint exposing (ExternalMsg(..), initialModel, Model, Msg, update, view)

import Data.Conversation exposing (Complaint)
import Data.User exposing (Session, User, usernameToString)
import Html exposing (button, div, form, Html, label, p, text, textarea)
import Html.Attributes exposing (class)
import Html.Events exposing (onInput, onSubmit)
import Http
import Request.Complaint
import Route
import Views.Input exposing (viewTextField, viewTextArea)


type Msg
    = SubmitForm
    | SetSubject String
    | SetMessage String
    | ComplaintRegistered (Result Http.Error Complaint)


type alias Error =
    ( Field, String )


type Field
    = Form
    | Subject
    | Message


type alias Model =
    { errors : List Error
    , subject : String
    , message : String
    , user : User
    }


type ExternalMsg
    = NoOp


initialModel : User -> Model
initialModel user =
    { errors = [], subject = "", message = "", user = user }


view : Session -> Model -> Html Msg
view _ model =
    form [ class "form-group", onSubmit SubmitForm ]
        [ viewTextField { id = "subject-input", label = "Targy", value = model.subject, msg = SetSubject }
        , viewTextArea { label_ = "Panasz", val = model.message, msg = SetMessage }
        , submitButton
        ]


submitButton : Html Msg
submitButton =
    div [ class "field" ]
        [ p [ class "control" ]
            [ button [ class "button is-primary" ] [ text "Kuldes" ] ]
        ]


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        -- Login request is submitted
        SubmitForm ->
            case validate model of
                [] ->
                    ( ( { model | errors = [] }, (Http.send ComplaintRegistered (Request.Complaint.newComplaint model)) )
                    , NoOp
                    )

                errors ->
                    ( ( { model | errors = errors }, Cmd.none ), NoOp )

        -- Email field changed
        SetSubject s ->
            ( ( { model | subject = s }, Cmd.none ), NoOp )

        -- Password field changed
        SetMessage msg ->
            ( ( { model | message = msg }, Cmd.none ), NoOp )

        -- Login failed with error
        ComplaintRegistered (Err error) ->
            let
                errorMessages =
                    case error of
                        Http.BadStatus response ->
                            [ (response.body |> Debug.log "bad response") ]

                        _ ->
                            [ ("Unable to process complaint. Reason: " ++ (toString error)) |> Debug.log "undefined resp" ]
            in
                ( ( { model | errors = List.map (\errorMessage -> ( Form, errorMessage )) errorMessages }
                  , Cmd.none
                  )
                , NoOp
                )

        -- Login succeeded
        ComplaintRegistered (Ok complaint) ->
            ( ( model, Route.modifyUrl (Route.Conversation complaint.id) )
            , NoOp
            )



-- TODO add validation for fields


validate : Model -> List Error
validate model =
    []
