module Page.Errored exposing (PageLoadError, view)

import Html exposing (div, Html, h3, text)


type alias Model =
  { errorMessage : String }


type PageLoadError =
  PageLoadError Model


view : PageLoadError -> Html msg
view (PageLoadError model) =
  div []
      [ h3 [] [ text model.errorMessage ] ]
