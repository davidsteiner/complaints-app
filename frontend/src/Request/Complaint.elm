module Request.Complaint exposing (..)

import Http
import HttpBuilder exposing (RequestBuilder, post, toRequest, withBody, withExpect)
import Json.Decode as Decode
import Json.Encode as Encode
import Data.Conversation as Conversation
import Data.User as User exposing (User, withAuthorisation)
import Request.Helpers exposing (apiUrl)


newComplaint : { r | subject : String, message : String, user : User } -> Http.Request Conversation.Conversation
newComplaint { subject, message, user } =
    let
        complaint =
            Encode.object
                [ ( "subject", Encode.string subject )
                , ( "message", Encode.string message )
                ]
    in
        apiUrl "/new-complaint/"
            |> post
            |> withAuthorisation user.token
            |> withBody (Http.jsonBody complaint)
            |> withExpect (Http.expectJson Conversation.decoder)
            |> toRequest
