module Reader
    open System
    open Tokenizer
    open Types

    type MutableList = System.Collections.Generic.List<Node>
    let inline addToMutableList (lst:MutableList) item = lst.Add(item); lst

    let errExpectedButEOF tok = ReaderError(sprintf "Expected %s, got EOF" tok)
    let errInvalid () = ReaderError("Invalid token")

    let quote = Symbol("quote")
    let quasiquote = Symbol("quasiquote")
    let unquote = Symbol("unquote")
    let spliceUnquote = Symbol("splice-unquote")
    let deref = Symbol("deref")
    let withMeta = Symbol("with-meta")

    let rec readForm = function
        | OpenParen::rest -> readList [] rest
        | OpenBracket::rest -> readVector (MutableList()) rest
        | OpenBrace::rest -> readMap [] rest
        | SingleQuote::rest -> wrapForm quote rest
        | Backtick::rest -> wrapForm quasiquote rest
        | Tilde::rest -> wrapForm unquote rest
        | SpliceUnquote::rest -> wrapForm spliceUnquote rest
        | At::rest -> wrapForm deref rest
        | Caret::rest -> readMeta rest
        | tokens -> readAtom tokens

    and wrapForm node tokens = 
        match readForm tokens with
        | Some(form), rest -> Some(List([node; form])), rest
        | None, _ -> raise <| errExpectedButEOF "form"

    and readList acc = function
        | CloseParen::rest -> Some(List(acc |> List.rev)), rest
        | [] -> raise <| errExpectedButEOF "')'"
        | tokens -> 
            match readForm tokens with
            | Some(form), rest -> readList (form::acc) rest
            | None, _ -> raise <| errExpectedButEOF "')'"

    and readVector acc = function
        | CloseBracket::rest -> Some(Vector(acc.ToArray())), rest
        | [] -> raise <| errExpectedButEOF "']'"
        | tokens -> 
            match readForm tokens with
            | Some(form), rest -> readVector (addToMutableList acc form) rest
            | None, _ -> raise <| errExpectedButEOF "']'"

    and readMap acc = function
        | CloseBrace::rest -> Some(Map(acc |> List.rev |> Map.ofList)), rest
        | [] -> raise <| errExpectedButEOF "'}'"
        | tokens -> 
            match readForm tokens with
            | Some(key), rest ->
                match readForm rest with
                | Some(v), rest -> readMap ((key, v)::acc) rest
                | None, _ -> raise <| errExpectedButEOF "'}'"
            | None, _ -> raise <| errExpectedButEOF "'}'"

    and readMeta = function
        | OpenBrace::rest ->
            let meta, rest = readMap [] rest
            match readForm rest with
            | Some(form), rest -> Some(List([withMeta; form; meta.Value])), rest
            | None, _ -> raise <| errExpectedButEOF "form"
        | _ -> raise <| errExpectedButEOF "map"

    and readAtom = function
        | Token("nil")::rest -> SomeNIL, rest
        | Token("true")::rest -> SomeTRUE, rest
        | Token("false")::rest -> SomeFALSE, rest
        | Tokenizer.String(str)::rest -> Some(String(str)), rest
        | Tokenizer.Keyword(kw)::rest -> Some(Keyword(kw)), rest
        | Tokenizer.Number(num)::rest -> Some(Number(Int64.Parse(num))), rest
        | Token(sym)::rest -> Some(Symbol(sym)), rest
        | [] -> None, []
        | _ -> raise <| errInvalid ()
        
    let rec readForms acc = function
        | [] -> List.rev acc
        | tokens -> 
            match readForm tokens with
            | Some(form), rest -> readForms (form::acc) rest
            | None, rest -> readForms acc rest

    let read_str str =
        tokenize str |> readForms []
