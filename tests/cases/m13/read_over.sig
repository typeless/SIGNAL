process READOVER =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: S := read("" when ^N)
   | W :: write("below b ", S < "b")
   | V :: write("starts a ", S > "a")
   | R --> W --> V
   |)
  where
    integer N, ZN;
    string S;
    label R, W, V;
  end;
