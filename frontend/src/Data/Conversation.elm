module Data.Conversation exposing (complaintDecoder, complaintListDecoder, decoder, Complaint, Conversation)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, optional, required)


type alias Conversation =
    { complaint : Complaint
    , messages : List ConversationMessage
    }


type alias Complaint =
    { subject : String
    , id : Int
    , owner : String
    }


type alias ConversationMessage =
    { sender : String
    , text : String
    }


decoder : Decoder Conversation
decoder =
    decode Conversation
        |> required "complaint" complaintDecoder
        |> required "messages" (Decode.list messageDecoder)


complaintDecoder : Decoder Complaint
complaintDecoder =
    decode Complaint
        |> required "subject" Decode.string
        |> required "id" Decode.int
        |> required "owner" Decode.string


complaintListDecoder : Decoder (List Complaint)
complaintListDecoder =
    Decode.list complaintDecoder


messageDecoder : Decoder ConversationMessage
messageDecoder =
    decode ConversationMessage
        |> required "sender" Decode.string
        |> required "text" Decode.string
