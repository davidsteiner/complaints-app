module Page.Register exposing (..)

import Html exposing (a, button, div, form, Html, h2, input, label, section, text)
import Html.Attributes exposing (attribute, class, for, id, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Data.User as User exposing (User, Session)
import Request.User exposing (storeSession)
import Route
import Views.Input exposing (viewEmailField, viewPasswordField, viewTextField)


type alias Error =
    ( Field, String )


type Field
    = Form
    | Username
    | Password
    | Email


type alias Model =
    { username : String
    , password : String
    , email : String
    , errors : List Error
    }


type Msg
    = SubmitForm
    | SetUsername String
    | SetPassword String
    | SetEmail String
    | RegisterCompleted (Result Http.Error User)


type ExternalMsg
    = NoOp
    | RedirectLogin User


initialModel : Model
initialModel =
    { username = ""
    , password = ""
    , email = ""
    , errors = []
    }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SubmitForm ->
            case validate model of
                [] ->
                    ( ( { model | errors = [] }
                      , Http.send RegisterCompleted (Request.User.register model)
                      )
                    , NoOp
                    )

                errors ->
                    ( ( { model | errors = errors }, Cmd.none ), NoOp )

        SetUsername username ->
            ( ( { model | username = username }, Cmd.none ), NoOp )

        SetPassword password ->
            ( ( { model | password = password }, Cmd.none ), NoOp )

        SetEmail email ->
            ( ( { model | email = email }, Cmd.none ), NoOp )

        RegisterCompleted (Err error) ->
            let
                errorMessages =
                    [ "Something went wrong!" ]

                -- TODO implement proper error handling from error message
            in
                ( ( { model | errors = List.map (\errorMessage -> ( Form, errorMessage )) errorMessages }
                  , Cmd.none
                  )
                , NoOp
                )

        RegisterCompleted (Ok user) ->
            ( ( model, Cmd.none ), RedirectLogin user )


view : Session -> Model -> Html Msg
view session model =
    case session of
        Just user ->
            -- If they user is logged in and somehow ends up on this page, show a message
            div [] [ text ("Már be vagy jelentkezve!") ]

        Nothing ->
            viewAnonymous model



-- The view one sees if they are routed to the registration page and are not logged in


viewAnonymous : Model -> Html Msg
viewAnonymous model =
    section [ class "hero is-fullheight is-dark is-bold" ]
        [ div [ class "hero-body" ] [ viewHero model ] ]


viewHero : Model -> Html Msg
viewHero model =
    div [ id "register-form", class "container" ]
        [ div [ class "columns is-vcentered" ]
            [ div [ class "column is-4 is-offset-4" ]
                [ h2 [ class "title" ] [ text "Regisztrálás" ]
                , div [ class "box" ] [ viewForm model ]
                ]
            ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    form [ class "form-group row", onSubmit SubmitForm ]
        [ viewTextField { id = "username", label = "Felhasználónév", value = model.username, msg = SetUsername }
        , viewEmailField { id = "email", label = "Email (opcionális)", value = model.email, msg = SetEmail }
        , viewPasswordField { id = "password", label = "Jelszó", value = model.password, msg = SetPassword }
        , div [ class "field" ]
            [ div [ class "control" ]
                [ button [ class "button is-success is-fullwidth is-large is-outlined" ] [ text "Regisztrálás" ] ]
            ]
        , a [ Route.href Route.Login ]
            [ text "Már regisztráltál? Jelentkezz be itt." ]
        ]



-- TODO finish validation logic


validate : Model -> List Error
validate model =
    []
