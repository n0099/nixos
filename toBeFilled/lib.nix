lib:

let
  readString =
    path:
    let
      content = lib.trim (lib.readFile path);
    in
    lib.throwIf (content == "") "Please fill content of file `${path}`." content;
  readStrings = path: lib.splitString "\n" (readString path);
in
{
  inherit readString readStrings;
}
