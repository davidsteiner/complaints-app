module Data.Conversation exposing (decoder, Conversation)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, optional, required)


type alias Conversation =
    { conversationId : String
    , subject : String
    , messages : List ConversationMessage
    }


type alias ConversationMessage =
    { sender : String
    , message : String
    , conversationId : String
    }


decoder : Decoder Conversation
decoder =
    decode Conversation
        |> required "subject" Decode.string
        |> required "conversationId" Decode.string
        |> required "messages" (Decode.list messageDecoder)


messageDecoder : Decoder ConversationMessage
messageDecoder =
    decode ConversationMessage
        |> required "sender" Decode.string
        |> required "message" Decode.string
        |> required "conversationId" Decode.string
