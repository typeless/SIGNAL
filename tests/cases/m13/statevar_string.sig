process STATEVARSTRING =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: A := read("" when ^N)
   | S ::= A when N > 1
   | Y := S? when ^N
   | W :: write("y=", Y)
   | R --> W
   |)
  where
    integer N, ZN;
    string A, Y;
    statevar string S init "x";
    label R, W;
  end;
