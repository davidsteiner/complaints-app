module Page.Login exposing (ExternalMsg(..), initialModel, Model, Msg(..), update, view)

import Html exposing (a, button, div, form, Html, h2, input, label, p, section, text)
import Html.Attributes exposing (class, for, id, type_)
import Html.Events exposing (onInput, onSubmit)
import Http

import Data.User exposing (User, Session)
import Request.User exposing (storeSession)
import Route
import Views.Input exposing (viewTextField, viewPasswordField)


type alias Error =
  ( Field, String )


type alias Model =
  { errors : List Error
  , username : String
  , password : String
  }


type Field
  = Form
  | Username 
  | Password


type Msg
  = SubmitForm
  | SetUsername String
  | SetPassword String
  | LoginCompleted (Result Http.Error User)


type ExternalMsg
  = NoOp
  | SetUser User


initialModel : Session -> Model
initialModel session =
  let
      username =
        case session of
          Just user ->
            Data.User.usernameToString user.username
          Nothing ->
            ""
  in
  { errors = []
  , username = username
  , password = ""
  }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
  case msg of
    -- Login request is submitted
    SubmitForm ->
      case validate model of
        [] ->
          ( ( { model | errors = [] }, ( Http.send LoginCompleted (Request.User.login model) ) )
          , NoOp )
        errors ->
          ( ( { model | errors = errors }, Cmd.none ), NoOp )

    -- Email field changed
    SetUsername name ->
      ( ( { model | username = name }, Cmd.none ), NoOp )

    -- Password field changed
    SetPassword password ->
      ( ( { model | password = password }, Cmd.none ), NoOp )

    -- Login failed with error
    LoginCompleted (Err error) ->
      let
          errorMessages =
            case error of
              Http.BadStatus response ->
                [ (response.body |> Debug.log "bad response") ]

              _ ->
                [ ("Unable to process Login. Reason: " ++ (toString error) ) |> Debug.log "undefined resp"]

      in
      ( ( { model | errors = List.map (\errorMessage -> ( Form, errorMessage) ) errorMessages }
        , Cmd.none )
      , NoOp
      ) 

    -- Login succeeded
    LoginCompleted (Ok user) ->
      let
          _ = Debug.log "Login completed" (Data.User.usernameToString user.username)
      in
      ( ( model, Cmd.batch [ storeSession user, Route.modifyUrl Route.Home ] )
      , SetUser user
      )

view : Session -> Model -> Html Msg
view session model =
  case session of
    Just user ->
      -- If they user is logged in and somehow ends up on this page, show a message
      div [] [ text (user.firstName ++ ", you are already logged in.") ]
    Nothing ->
      section [ class "hero is-fullheight is-dark is-bold" ]
              [ div [ class "hero-body" ] [ viewHero model ] ]

viewHero : Model -> Html Msg
viewHero model =
  div [ id "login-form", class "container" ]
      [ div [ class "columns is-vcentered" ]
            [ div [ class "column is-4 is-offset-4" ]
                  [ h2 [ class "title" ] [ text "Login" ]
                  , div [ class "box" ] [ viewForm model ] 
                  ]
            ]
      ]

viewForm : Model -> Html Msg
viewForm model =
  form [ class "form-group row", onSubmit SubmitForm ]
       [ viewTextField { id = "username", label = "Username", value = model.username, msg = SetUsername }
       , viewPasswordField { id = "password", label = "Password", value = model.password, msg = SetPassword }
       , div [ class "field" ]
             [ div [ class "control" ]
                   [ button [ class "button is-success is-fullwidth is-large is-outlined" ] [ text "Login" ] ]
             ]
       , a [ Route.href Route.Register ]
           [ text "Not a member yet?" ]
       ]


-- TODO add validation for fields
validate : Model -> List Error
validate model = []

