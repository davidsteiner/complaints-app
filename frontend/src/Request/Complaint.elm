module Request.Complaint exposing (complaintList, conversation, newComplaint, sendMessage)

import Http
import HttpBuilder exposing (get, RequestBuilder, post, toRequest, withBody, withExpect)
import Json.Decode as Decode
import Json.Encode as Encode
import Data.Conversation as Conversation
import Data.User as User exposing (User, withAuthorisation)
import Request.Helpers exposing (apiUrl)


newComplaint : { r | subject : String, message : String, user : User } -> Http.Request Conversation.Complaint
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
            |> withExpect (Http.expectJson Conversation.complaintDecoder)
            |> toRequest


sendMessage : User -> String -> Int -> Http.Request Conversation.Conversation
sendMessage user text complaintId =
    let
        message =
            Encode.object
                [ ( "text", Encode.string text )
                , ( "complaintId", Encode.int complaintId )
                ]
    in
        apiUrl "/send-message/"
            |> post
            |> withAuthorisation user.token
            |> withBody (Http.jsonBody message)
            |> withExpect (Http.expectJson Conversation.decoder)
            |> toRequest


complaintList : User -> Http.Request (List Conversation.Complaint)
complaintList user =
    apiUrl "/complaints/"
        |> get
        |> withAuthorisation user.token
        |> withExpect (Http.expectJson Conversation.complaintListDecoder)
        |> toRequest


conversation : User -> Int -> Http.Request Conversation.Conversation
conversation user complaintId =
    apiUrl ("/conversation/" ++ toString complaintId ++ "/")
        |> get
        |> withAuthorisation user.token
        |> withExpect (Http.expectJson Conversation.decoder)
        |> toRequest
