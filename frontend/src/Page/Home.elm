module Page.Home exposing (Model, view)

import Html exposing (h1, h2, Html, div, li, ol, section, text)
import Html.Attributes exposing (class)
import Data.Conversation exposing (Complaint)
import Data.User exposing (Session)
import Views.ComplaintMenu exposing (viewMenu)


type alias Model =
    List Complaint


view : Session -> List Complaint -> Html msg
view session complaints =
    case session of
        Nothing ->
            div [] []

        Just user ->
            div []
                [ div [ class "is-hidden-desktop" ] [ viewMenu user complaints ]
                , div [ class "is-hidden-touch" ] [ viewBanner, div [ class "content" ] [ viewInstructions ] ]
                ]


viewBanner : Html msg
viewBanner =
    section [ class "hero is-primary" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ h1 [ class "title" ] [ text "Észrevételjelentés" ]
                , h2 [ class "subtitle" ] [ text "Használati útmutató" ]
                ]
            ]
        ]


viewInstructions : Html msg
viewInstructions =
    let
        instructions =
            [ div [] [ text "Új észrevételt baloldalt az ", div [ class "button is-dark is-outlined is-small" ] [ text "Új észrevétel" ], text " gombbal lehet jelenteni." ]
            , text "Korábbi észrevételek a gomb alatt találhatók."
            , text "Egy észrevételre kattintva megtekinthető az észrevételhez tartozó üzenetek, illetve új üzenet/válasz küldhető."
            ]
    in
        instructions
            |> List.map (\inst -> li [] [ inst ])
            |> ol []
