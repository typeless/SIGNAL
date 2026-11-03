process SHAREDINITSTRING =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: A := read("" when ^N)
   | PS ^= N
   | PS ::= A when N modulo 2 = 0
   | W :: write("p=", PS)
   | R --> W
   |)
  where
    integer N, ZN;
    string A;
    shared string PS init "x";
    label R, W;
  end;
