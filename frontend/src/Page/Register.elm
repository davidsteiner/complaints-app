module Page.Register exposing (ExternalMsg(..), initialModel, Model, Msg, update, view)

import Data.User as User exposing (Username, Session)
import Dict
import Html exposing (a, button, div, form, Html, h2, section, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick, onSubmit)
import Http
import Maybe.Extra exposing (values)
import Regex exposing (caseInsensitive, contains, regex, Regex)
import Request.User exposing (register)
import Route
import Util exposing ((=>))
import Views.Input exposing (InputError, viewEmailField, viewPasswordField, viewTextField)


type alias Model =
    { username : String
    , password : String
    , confirmPassword : String
    , email : String
    , serverError : InputError
    }


type Msg
    = SubmitForm
    | SetUsername String
    | SetPassword String
    | SetConfirmPassword String
    | SetEmail String
    | ClearServerError
    | RegisterCompleted (Result Http.Error Username)


type ExternalMsg
    = NoOp
    | RedirectLogin Username


initialModel : Model
initialModel =
    { username = ""
    , password = ""
    , confirmPassword = ""
    , email = ""
    , serverError = Nothing
    }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SubmitForm ->
            if hasErrors model then
                { model | serverError = Nothing } => Cmd.none => NoOp
            else
                { model | serverError = Nothing } => Http.send RegisterCompleted (register model) => NoOp

        SetUsername username ->
            { model | username = username } => Cmd.none => NoOp

        SetPassword password ->
            { model | password = password } => Cmd.none => NoOp

        SetConfirmPassword password ->
            { model | confirmPassword = password } => Cmd.none => NoOp

        SetEmail email ->
            { model | email = email } => Cmd.none => NoOp

        RegisterCompleted (Err error) ->
            let
                errorMessage =
                    case error of
                        Http.BadStatus response ->
                            if response.status.code == 400 then
                                "Sikertelen regisztráció"
                            else
                                "Váratlan hiba a regisztrációban"

                        _ ->
                            "Szerver nem elérhető"
            in
                { model | serverError = Just errorMessage } => Cmd.none => NoOp

        RegisterCompleted (Ok user) ->
            model => Cmd.none => RedirectLogin user

        ClearServerError ->
            { model | serverError = Nothing } => Cmd.none => NoOp


view : Session -> Model -> Html Msg
view session model =
    case session of
        Just user ->
            div [] [ text ("Már be vagy jelentkezve!") ]

        Nothing ->
            viewAnonymous model


viewServerError : Model -> Html Msg
viewServerError model =
    case model.serverError of
        Nothing ->
            div [] []

        Just error ->
            div [ class "notification is-danger" ]
                [ button [ class "delete", onClick ClearServerError ] []
                , text error
                ]


viewAnonymous : Model -> Html Msg
viewAnonymous model =
    section [ class "hero is-fullheight is-light is-bold" ]
        [ div [ class "hero-body" ] [ viewHero model ] ]


viewHero : Model -> Html Msg
viewHero model =
    div [ id "register-form", class "container" ]
        [ div [ class "columns is-vcentered" ]
            [ div [ class "column is-4 is-offset-4" ]
                [ h2 [ class "title" ] [ text "Regisztrálás" ]
                , viewServerError model
                , div [ class "box" ] [ viewForm model ]
                ]
            ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    form [ class "form-group row", onSubmit SubmitForm ]
        [ viewTextField "Felhasználónév" model.username SetUsername (validateUsername model)
        , viewEmailField "Email (opcionális)" model.email SetEmail (validateEmail model)
        , viewPasswordField "Jelszó" model.password SetPassword (validatePassword model)
        , viewPasswordField "Jelszó megerősítése" model.confirmPassword SetConfirmPassword (validateConfirmPassword model)
        , div [ class "field" ]
            [ div [ class "control" ]
                [ button [ class "button is-primary is-fullwidth is-large is-outlined" ] [ text "Regisztrálás" ] ]
            ]
        , a [ Route.href Route.Login ]
            [ text "Már regisztráltál? Jelentkezz be itt." ]
        ]


hasErrors : Model -> Bool
hasErrors model =
    let
        validationResults =
            [ validateUsername model
            , validatePassword model
            , validateEmail model
            ]
    in
        not <| List.isEmpty <| values validationResults


validateUsername : Model -> InputError
validateUsername model =
    if String.length model.username < 4 then
        Just "A felhasználónévnek legalább 4 karakternek kell lennie."
    else
        Nothing


validatePassword : Model -> InputError
validatePassword model =
    if String.length model.password < 8 then
        Just "A jelszónak legalább 8 karakternek kell lennie."
    else
        Nothing


validateConfirmPassword : Model -> InputError
validateConfirmPassword model =
    if model.password == model.confirmPassword then
        Nothing
    else
        Just "A két jelszónak egyeznie kell."


validateEmail : Model -> InputError
validateEmail model =
    if contains emailRegex model.email || String.isEmpty model.email then
        Nothing
    else
        Just "Helytelen email formátum."


emailRegex : Regex
emailRegex =
    caseInsensitive (regex "^\\S+@\\S+\\.\\S+$")
