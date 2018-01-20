module Views.Input exposing (InputError, viewEmailField, viewPasswordField, viewTextArea, viewTextField)

import Html exposing (div, Html, input, label, p, text, textarea)
import Html.Attributes exposing (class, maxlength, type_, value)
import Html.Events exposing (onInput)
import Maybe.Extra exposing (isNothing)


buildInputClass : String -> InputError -> String
buildInputClass baseClass error =
    if isNothing error then
        baseClass
    else
        baseClass ++ " is-warning"


errorLabel : InputError -> Html msg
errorLabel error =
    case error of
        Nothing ->
            text ""

        Just errorString ->
            p [ class "help is-dark" ] [ text errorString ]


viewTextField : String -> String -> (String -> msg) -> InputError -> Html msg
viewTextField =
    viewField "text" Nothing


viewPasswordField : String -> String -> (String -> msg) -> InputError -> Html msg
viewPasswordField =
    viewField "password" (Just "password-input")


viewEmailField : String -> String -> (String -> msg) -> InputError -> Html msg
viewEmailField =
    viewField "email" (Just "email-input")


viewField : String -> Maybe String -> String -> String -> (String -> msg) -> InputError -> Html msg
viewField inputType extraClass label_ inputValue msg error =
    let
        inputClass =
            case extraClass of
                Nothing ->
                    buildInputClass "input is-large" error

                Just extra ->
                    (buildInputClass "input is-large" error) ++ " " ++ extra
    in
        div [ class "field" ]
            [ label [ class "label" ] [ text label_ ]
            , input [ maxlength 30, type_ inputType, class inputClass, onInput msg, value inputValue ] []
            , errorLabel error
            ]


viewTextArea : String -> String -> (String -> msg) -> InputError -> Html msg
viewTextArea label_ val msg error =
    div [ class "field" ]
        [ label [ class "label" ] [ text label_ ]
        , div [ class "control" ] [ textarea [ class <| buildInputClass "textarea" error, value val, onInput msg ] [] ]
        , errorLabel error
        ]


type alias InputError =
    Maybe String
