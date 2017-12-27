module Main exposing (..)

import Html exposing (div, Html, program, section, text)
import Html.Attributes exposing (class, id)
import Http
import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Task
import Data.Conversation exposing (Complaint)
import Data.User as User exposing (User, Session)
import Page.Conversation as Conversation
import Page.Errored exposing (PageLoadError)
import Page.Home as Home
import Page.Login as Login
import Page.NewComplaint as NewComplaint
import Page.NotFound as NotFound
import Page.Register as Register
import Ports
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
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString User.decoder >> Result.toMaybe)


initialPage : Page
initialPage =
    Blank



-- Model


type Page
    = Blank
    | Login Login.Model
    | Register Register.Model
    | Home Home.Model
    | Errored PageLoadError
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
                            [ div [ class "column is-3 is-hidden-touch" ] [ ComplaintMenu.viewMenu complaints ]
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
    | SetUser (Maybe User)
    | SetRoute (Maybe Route)
    | ComplaintListUpdated (Result Http.Error (List Complaint))
    | ConversationLoaded User (Result Http.Error Data.Conversation.Conversation)



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

                            Login.SetUser user ->
                                { model | session = Just user }
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

                    newModel =
                        case msgFromPage of
                            NewComplaint.NoOp ->
                                model
                in
                    ( { newModel | pageState = Loaded (NewComplaint pageModel) }, Cmd.map NewComplaintMsg cmd )

            ( ConversationMsg subMsg, Conversation subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Conversation.update subMsg subModel
                in
                    ( { model | pageState = Loaded (Conversation pageModel) }, Cmd.map ConversationMsg cmd )

            ( NavbarMsg _, _ ) ->
                let
                    newNavbarState =
                        not model.navbarState
                in
                    ( { model | navbarState = newNavbarState }, Cmd.none )

            ( ComplaintListUpdated (Ok complaints), _ ) ->
                ( { model | complaints = complaints }, Cmd.none )

            ( ComplaintListUpdated (Err err), _ ) ->
                ( { model | complaints = [] }, Cmd.none )
                    |> Debug.log (toString err)

            ( ConversationLoaded user (Ok conversation), _ ) ->
                let
                    subModel =
                        Conversation.initialModel conversation user
                in
                    ( { model | pageState = Loaded (Conversation subModel) }, Cmd.none )

            ( ConversationLoaded _ (Err err), _ ) ->
                ( model, Cmd.none )
                    |> Debug.log (toString err)

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
    case route of
        Route.Login ->
            ( model, Cmd.none )

        Route.Home ->
            ( { model | pageState = Loaded (Home model.complaints) }, Task.attempt ComplaintListUpdated (ComplaintMenu.init user) )

        Route.Logout ->
            -- Set session to nothing both in the model and in the local storage and redirect to Home
            ( { model | session = Nothing }, Cmd.batch [ Ports.storeSession Nothing, Route.modifyUrl Route.Home ] )

        Route.Register ->
            ( model, Cmd.none )

        Route.NewComplaint ->
            ( { model | pageState = Loaded (NewComplaint (NewComplaint.initialModel user)) }, Task.attempt ComplaintListUpdated (ComplaintMenu.init user) )

        Route.Conversation complaintId ->
            let
                cmd =
                    Cmd.batch [ Task.attempt (ConversationLoaded user) (Conversation.init user complaintId), Task.attempt ComplaintListUpdated (ComplaintMenu.init user) ]
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
