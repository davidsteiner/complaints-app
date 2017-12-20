module Views.Input exposing (viewEmailField, viewPasswordField, viewTextArea, viewTextField)

import Html exposing (div, Html, input, label, text, textarea)
import Html.Attributes exposing (class, id, type_, value)
import Html.Events exposing (onInput)


viewTextField : { id : String, label : String, value : String, msg : String -> msg } -> Html msg
viewTextField { id, label, value, msg } =
    viewField_ { id_ = id, label_ = label, inputType = "text", inputClass = "input is-large", inputValue = value, msg = msg }


viewPasswordField : { id : String, label : String, value : String, msg : String -> msg } -> Html msg
viewPasswordField { id, label, value, msg } =
    viewField_ { id_ = id, label_ = label, inputType = "password", inputClass = "input is-large password-input", inputValue = value, msg = msg }


viewEmailField : { id : String, label : String, value : String, msg : String -> msg } -> Html msg
viewEmailField { id, label, value, msg } =
    viewField_ { id_ = id, label_ = label, inputType = "email", inputClass = "input is-large email-input", inputValue = value, msg = msg }


viewField_ : { id_ : String, label_ : String, inputType : String, inputClass : String, inputValue : String, msg : String -> msg } -> Html msg
viewField_ { id_, label_, inputType, inputClass, inputValue, msg } =
    div [ class "field" ]
        [ label [ class "label" ] [ text label_ ]
        , input [ id id_, type_ inputType, class inputClass, onInput msg, value inputValue ] []
        ]


viewTextArea : { label_ : String, val : String, msg : String -> msg } -> Html msg
viewTextArea { label_, val, msg } =
    div [ class "field" ]
        [ label [ class "label" ] [ text label_ ]
        , div [ class "control" ] [ textarea [ class "textarea", value val, onInput msg ] [] ]
        ]
