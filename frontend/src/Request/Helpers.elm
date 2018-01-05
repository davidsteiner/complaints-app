module Request.Helpers exposing (apiUrl, send)

import Data.User exposing (User, tokenToString)
import Http exposing (Request)
import Jwt exposing (JwtError, sendCheckExpired)


apiUrl : String -> String
apiUrl str =
    "http://localhost:8000/api" ++ str


send : User -> (Result JwtError a -> msg) -> Request a -> Cmd msg
send user msgCreator request =
    let
        token =
            tokenToString user.token
    in
        sendCheckExpired token msgCreator request
