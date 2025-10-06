lib:

let
  readString = path: lib.trim (lib.readFile path);
  readStrings = path: lib.splitString "\n" (readString path);
in
{
  inherit readString readStrings;
}
