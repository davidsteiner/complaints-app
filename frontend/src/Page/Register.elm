module Page.Register exposing (..)

import Html exposing (a, button, div, form, Html, h2, input, label, section, text)
import Html.Attributes exposing (attribute, class, for, id, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Data.User as User exposing (User, Session)
import Request.User exposing (storeSession)
import Route
import Views.Input exposing (viewEmailField, viewPasswordField, viewTextField)


type alias Error =
    Maybe String


type alias Model =
    { username : String
    , password : String
    , email : String
    , serverError : Error
    }


type Msg
    = SubmitForm
    | SetUsername String
    | SetPassword String
    | SetEmail String
    | ClearServerError
    | RegisterCompleted (Result Http.Error User)


type ExternalMsg
    = NoOp
    | RedirectLogin User


initialModel : Model
initialModel =
    { username = ""
    , password = ""
    , email = ""
    , serverError = Nothing
    }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SubmitForm ->
            case validate model of
                [] ->
                    ( ( { model | serverError = Nothing }
                      , Http.send RegisterCompleted (Request.User.register model)
                      )
                    , NoOp
                    )

                errors ->
                    ( ( { model | serverError = Nothing }, Cmd.none ), NoOp )

        SetUsername username ->
            ( ( { model | username = username }, Cmd.none ), NoOp )

        SetPassword password ->
            ( ( { model | password = password }, Cmd.none ), NoOp )

        SetEmail email ->
            ( ( { model | email = email }, Cmd.none ), NoOp )

        RegisterCompleted (Err error) ->
            let
                errorMessage =
                    case error of
                        Http.BadStatus response ->
                            "Sikertelen regisztráció"

                        _ ->
                            "Váratlan hiba a regisztrációban"
            in
                ( ( { model | serverError = Just errorMessage }
                  , Cmd.none
                  )
                , NoOp
                )

        RegisterCompleted (Ok user) ->
            ( ( model, Cmd.none ), RedirectLogin user )

        ClearServerError ->
            ( ( { model | serverError = Nothing }, Cmd.none )
            , NoOp
            )


view : Session -> Model -> Html Msg
view session model =
    case session of
        Just user ->
            -- If they user is logged in and somehow ends up on this page, show a message
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
    section [ class "hero is-fullheight is-dark is-bold" ]
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
