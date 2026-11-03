process READEMPTY =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: S := read("" when ^N)
   | W :: write("[", S)
   | V :: write("empty ", S = "")
   | U :: write("below a ", S < "a")
   | R --> W --> V --> U
   |)
  where
    integer N, ZN;
    string S;
    label R, W, V, U;
  end;
