module Main exposing (..)

import Html exposing (div, Html, program, section, text)
import Html.Attributes exposing (class, id)
import Http
import Json.Decode as Decode exposing (Value)
import Jwt exposing (JwtError(TokenExpired))
import Navigation exposing (Location)
import Task
import Data.Conversation exposing (Complaint)
import Data.User as User exposing (AuthToken(AuthToken), User, Session, tokenToUser)
import Page.Conversation as Conversation
import Page.Errored exposing (ErrorMessage)
import Page.Home as Home
import Page.Login as Login
import Page.NewComplaint as NewComplaint
import Page.NotFound as NotFound
import Page.Register as Register
import Ports
import Request.Helpers exposing (send)
import Request.User exposing (refreshTokenCmd)
import Route exposing (Route)
import Task
import Views.ComplaintMenu as ComplaintMenu
import Views.Navbar as Navbar


init : Value -> Location -> ( Model, Cmd Msg )
init val location =
    setRoute (Route.fromLocation location)
        { session = (decodeUserFromJson val)
        , pageState = Loaded initialPage
        , navbarState = False
        , complaints = []
        }


decodeUserFromJson : Value -> Maybe User
decodeUserFromJson json =
    case Decode.decodeValue Decode.string <| json of
        Ok tokenStr ->
            tokenToUser <| AuthToken tokenStr

        Err err ->
            Nothing
                |> Debug.log ("Failed to decode user from stored session: " ++ err)


initialPage : Page
initialPage =
    Blank



-- Model


type Page
    = Blank
    | Login Login.Model
    | Register Register.Model
    | Home Home.Model
    | Errored ErrorMessage
    | NotFound
    | NewComplaint NewComplaint.Model
    | Conversation Conversation.Model


type PageState
    = Loaded Page
    | TransitioningFrom Page


type alias Model =
    { session : Session
    , pageState : PageState
    , navbarState : Navbar.State
    , complaints : List Complaint
    }



-- View


view : Model -> Html Msg
view model =
    case model.pageState of
        Loaded page ->
            frame model.session model.navbarState (viewPage model.session page) False model.complaints

        TransitioningFrom page ->
            frame model.session model.navbarState (viewPage model.session page) True model.complaints


frame : Session -> Navbar.State -> Html Msg -> Bool -> List Complaint -> Html Msg
frame session navbarState content isLoading complaints =
    case session of
        Nothing ->
            div [ id "page-frame" ]
                [ content ]

        Just user ->
            div [ id "page-frame" ]
                [ Navbar.viewNavbar navbarState isLoading complaints
                    |> Html.map NavbarMsg
                , section [ class "section" ]
                    [ div [ class "container" ]
                        [ div [ class "columns" ]
                            [ div [ class "column is-3 is-hidden-touch" ] [ ComplaintMenu.viewMenu user complaints ]
                            , div [ class "column is-9" ] [ content ]
                            ]
                        ]
                    ]
                ]


viewPage : Session -> Page -> Html Msg
viewPage session page =
    case page of
        Login subModel ->
            Login.view session subModel
                |> Html.map LoginMsg

        Register subModel ->
            Register.view session subModel
                |> Html.map RegisterMsg

        Home subModel ->
            Home.view session subModel

        NewComplaint subModel ->
            NewComplaint.view session subModel
                |> Html.map NewComplaintMsg

        Conversation subModel ->
            Conversation.view session subModel
                |> Html.map ConversationMsg

        NotFound ->
            NotFound.view

        Blank ->
            Html.div [] []

        Errored errorMessage ->
            Page.Errored.view errorMessage



-- Message


type Msg
    = LoginMsg Login.Msg
    | RegisterMsg Register.Msg
    | NavbarMsg Navbar.Msg
    | NewComplaintMsg NewComplaint.Msg
    | ConversationMsg Conversation.Msg
    | SetRoute (Maybe Route)
    | ComplaintListUpdated (Result JwtError (List Complaint))
    | ConversationLoaded User (Result JwtError Data.Conversation.Conversation)
    | TokenRefreshed (Result JwtError AuthToken)



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        page =
            case model.pageState of
                Loaded page ->
                    page

                TransitioningFrom page ->
                    page
    in
        case ( msg, page ) of
            ( SetRoute route, _ ) ->
                setRoute route model

            ( LoginMsg subMsg, Login subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Login.update subMsg subModel

                    newModel =
                        case msgFromPage of
                            Login.NoOp ->
                                model

                            Login.SetSession session ->
                                { model | session = session }
                in
                    ( { newModel | pageState = Loaded (Login pageModel) }, Cmd.map LoginMsg cmd )

            ( RegisterMsg subMsg, Register subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Register.update subMsg subModel

                    newModel =
                        case msgFromPage of
                            Register.NoOp ->
                                { model | pageState = Loaded (Register pageModel) }

                            Register.RedirectLogin user ->
                                { model | pageState = Loaded (Login (Login.initialModel (Just user))) }
                in
                    ( newModel, Cmd.map RegisterMsg cmd )

            ( NewComplaintMsg subMsg, NewComplaint subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        NewComplaint.update subMsg subModel
                in
                    case msgFromPage of
                        NewComplaint.NoOp ->
                            ( { model | pageState = Loaded <| NewComplaint pageModel }, Cmd.map NewComplaintMsg cmd )

                        NewComplaint.ErrorReceived jwtError ->
                            ( { model | pageState = Loaded <| Errored jwtError }, Cmd.none )

            ( ConversationMsg subMsg, Conversation subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Conversation.update subMsg subModel
                in
                    case msgFromPage of
                        Conversation.NoOp ->
                            ( { model | pageState = Loaded <| Conversation pageModel }, Cmd.map ConversationMsg cmd )

                        Conversation.ErrorReceived jwtError ->
                            ( { model | pageState = Loaded <| Errored jwtError }, Cmd.none )

            ( NavbarMsg _, _ ) ->
                let
                    newNavbarState =
                        not model.navbarState
                in
                    ( { model | navbarState = newNavbarState }, Cmd.none )

            ( ComplaintListUpdated (Ok complaints), Home subModel ) ->
                ( { model | complaints = complaints, pageState = Loaded (Home complaints) }, Cmd.none )

            ( ComplaintListUpdated (Ok complaints), _ ) ->
                ( { model | complaints = complaints }, Cmd.none )

            ( ComplaintListUpdated (Err err), _ ) ->
                case err of
                    TokenExpired ->
                        ( { model | session = Nothing }, Cmd.batch [ Ports.storeSession Nothing, Route.modifyUrl Route.Home ] )
                            |> Debug.log "Logging user out as jwt has expired."

                    otherError ->
                        ( { model | pageState = Loaded <| Errored otherError }, Cmd.none )

            ( ConversationLoaded user (Ok conversation), _ ) ->
                let
                    subModel =
                        Conversation.initialModel conversation user
                in
                    ( { model | pageState = Loaded (Conversation subModel) }, Cmd.none )

            ( ConversationLoaded _ (Err err), _ ) ->
                case err of
                    TokenExpired ->
                        ( { model | session = Nothing }, Cmd.batch [ Ports.storeSession Nothing, Route.modifyUrl Route.Home ] )
                            |> Debug.log "Logging user out as jwt has expired."

                    otherError ->
                        ( { model | pageState = Loaded <| Errored otherError }, Cmd.none )

            ( TokenRefreshed (Ok newToken), _ ) ->
                case model.session of
                    Nothing ->
                        -- We do not want to overwrite the session if we've already logged out for some reason
                        ( model, Cmd.none )

                    Just _ ->
                        case tokenToUser newToken of
                            Nothing ->
                                ( model, Cmd.none )
                                    |> Debug.log "Something went wrong with parsing the token. The token was not refreshed."

                            Just user ->
                                ( { model | session = Just user }, Ports.storeSession <| Just <| User.tokenToString user.token )

            ( TokenRefreshed (Err err), _ ) ->
                case err of
                    TokenExpired ->
                        ( { model | session = Nothing }, Cmd.batch [ Ports.storeSession Nothing, Route.modifyUrl Route.Home ] )
                            |> Debug.log "Logging user out as jwt has expired before we could refresh the token"

                    otherError ->
                        ( { model | pageState = Loaded <| Errored otherError }, Cmd.none )

            ( _, _ ) ->
                ( model, Cmd.none )



-- Routing


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    let
        transition toMsg task =
            ( { model | pageState = TransitioningFrom (getPage model.pageState) }, Task.attempt toMsg task )
    in
        case maybeRoute of
            Nothing ->
                ( { model | pageState = Loaded NotFound }, Cmd.none )

            Just route ->
                case model.session of
                    Just user ->
                        setAuthenticatedRoute route model user

                    Nothing ->
                        setUnauthenticatedRoute route model


setAuthenticatedRoute : Route -> Model -> User -> ( Model, Cmd Msg )
setAuthenticatedRoute route model user =
    let
        refreshToken =
            refreshTokenCmd user TokenRefreshed

        updateComplaintListCmd =
            send user ComplaintListUpdated (ComplaintMenu.init user)
    in
        case route of
            Route.Login ->
                ( model, refreshToken )

            Route.Home ->
                ( { model | pageState = Loaded (Home model.complaints) }, Cmd.batch [ updateComplaintListCmd, refreshToken ] )

            Route.Logout ->
                -- Set session to nothing both in the model and in the local storage and redirect to Home
                ( { model | session = Nothing }, Cmd.batch [ Ports.storeSession Nothing, Route.modifyUrl Route.Home ] )

            Route.Register ->
                ( model, Cmd.none )

            Route.NewComplaint ->
                ( { model | pageState = Loaded (NewComplaint (NewComplaint.initialModel user)) }, Cmd.batch [ updateComplaintListCmd, refreshToken ] )

            Route.Conversation complaintId ->
                let
                    cmd =
                        Cmd.batch [ send user (ConversationLoaded user) (Conversation.init user complaintId), updateComplaintListCmd, refreshToken ]
                in
                    ( model, cmd )


setUnauthenticatedRoute : Route -> Model -> ( Model, Cmd Msg )
setUnauthenticatedRoute route model =
    case route of
        Route.Login ->
            ( { model | pageState = Loaded (Login (Login.initialModel Nothing)) }, Cmd.none )

        Route.Register ->
            ( { model | pageState = Loaded (Register Register.initialModel) }, Cmd.none )

        _ ->
            ( model, Route.modifyUrl Route.Login )


getPage : PageState -> Page
getPage pageState =
    case pageState of
        Loaded page ->
            page

        TransitioningFrom page ->
            page



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Main


main : Program Value Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
