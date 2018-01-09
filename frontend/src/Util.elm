module Util exposing ((=>), viewIf)

import Html exposing (Html)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)
infixl 0 =>


viewIf : Bool -> Html msg -> Html msg
viewIf condition content =
    if condition then
        content
    else
        Html.text ""
