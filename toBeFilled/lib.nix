lib:

let
  readString =
    path:
    let
      content = path |> lib.readFile |> lib.trim;
    in
    lib.throwIf (content == "") "Please fill content of file `${path}`." content;
  readStrings = path: path |> readString |> lib.splitString "\n";
in
{
  inherit readString readStrings;
}
