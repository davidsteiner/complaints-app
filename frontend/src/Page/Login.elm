module Page.Login exposing (ExternalMsg(..), initialModel, Model, Msg(..), update, view)

import Html exposing (a, button, div, form, Html, h2, section, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick, onSubmit)
import Http
import Data.User exposing (AuthToken, User, Username, Session, tokenToUser)
import Request.User exposing (storeSession)
import Route
import Util exposing ((=>))
import Views.Input exposing (viewTextField, viewPasswordField)


type alias Error =
    Maybe String


type alias Model =
    { serverError : Error
    , username : String
    , password : String
    }


type Msg
    = SubmitForm
    | SetUsername String
    | SetPassword String
    | ClearServerError
    | LoginCompleted (Result Http.Error AuthToken)


type ExternalMsg
    = NoOp
    | SetSession Session


initialModel : Maybe Username -> Model
initialModel maybeName =
    let
        usernameString =
            case maybeName of
                Just username ->
                    Data.User.usernameToString username

                Nothing ->
                    ""
    in
        { serverError = Nothing
        , username = usernameString
        , password = ""
        }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SubmitForm ->
            { model | serverError = Nothing } => Http.send LoginCompleted (Request.User.login model) => NoOp

        SetUsername name ->
            { model | username = name } => Cmd.none => NoOp

        SetPassword password ->
            { model | password = password } => Cmd.none => NoOp

        LoginCompleted (Err error) ->
            let
                errorMessage =
                    case error of
                        Http.BadStatus response ->
                            if response.status.code == 400 then
                                "Hibás felhasználónév vagy jelszó"
                                    |> Debug.log response.body
                            else
                                "Váratlan hiba a bejelentkezésben"

                        _ ->
                            "Szerver elérhetetlen"
            in
                { model | serverError = Just errorMessage } => Cmd.none => NoOp

        LoginCompleted (Ok token) ->
            let
                session =
                    tokenToUser token
            in
                model => Cmd.batch [ storeSession session, Route.modifyUrl Route.Home ] => SetSession session

        ClearServerError ->
            { model | serverError = Nothing } => Cmd.none => NoOp


view : Session -> Model -> Html Msg
view session model =
    case session of
        Just user ->
            div [] [ text ("Már be vagy jelentkezve!") ]

        Nothing ->
            section [ class "hero is-fullheight is-light is-bold" ]
                [ div [ class "hero-body" ] [ viewHero model ] ]


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


viewHero : Model -> Html Msg
viewHero model =
    div [ id "login-form", class "container" ]
        [ div [ class "columns is-vcentered" ]
            [ div [ class "column is-4 is-offset-4" ]
                [ h2 [ class "title" ] [ text "Bejelentkezés" ]
                , viewServerError model
                , div [ class "box" ] [ viewForm model ]
                ]
            ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    form [ class "form-group row", onSubmit SubmitForm ]
        [ viewTextField "Felhasználónév" model.username SetUsername Nothing
        , viewPasswordField "Jelszó" model.password SetPassword Nothing
        , div [ class "field" ]
            [ div [ class "control" ]
                [ button [ class "button is-primary is-fullwidth is-large is-outlined" ] [ text "Bejelentkezés" ] ]
            ]
        , a [ Route.href Route.Register ]
            [ text "Még nem regisztráltál?" ]
        ]
