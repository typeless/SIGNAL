process STATEREAD =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: A := read("" when ^N)
   | B := A $ 1 init "b0"
   | C := B $ 1 init "c0"
   | L := A $ 2
   | KEEP := A /= "skip"
   | AK := A when KEEP
   | Q := AK cell (not KEEP) init "none"
   | V := var AK
   | V ^= A
   | P ^= A
   | P ::= A when KEEP
   | W :: write("a=", A)
   | X :: write("b=", B)
   | Y :: write("c=", C)
   | Z :: write("l=", L)
   | U :: write("q=", Q)
   | T :: write("v=", V)
   | S :: write("p=", P)
   | R --> W --> X --> Y --> Z --> U --> T --> S
   |)
  where
    integer N, ZN;
    string A, B, C, L, Q, V, AK;
    shared string P;
    boolean KEEP;
    label R, W, X, Y, Z, U, T, S;
  end;
