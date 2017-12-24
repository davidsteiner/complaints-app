module Request.Helpers exposing (apiUrl)


apiUrl : String -> String
apiUrl str =
    "http://complaint.david-steiner.co.uk/api" ++ str
