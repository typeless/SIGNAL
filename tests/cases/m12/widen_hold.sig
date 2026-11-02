process WIDENHOLD =
  ( ? integer N; dreal A;
    ! dreal Y1, Y2, Y3, Y4; )
  (| X := A when N > 1
   | B := N > 0
   | Y1 := X cell B init 2.5
   | Y2 := var X init 3.5
   | Y2 ^= N
   | S ::= X
   | Y3 := S? when B
   | P ::= A when N > 2
   | P ^= N
   | Y4 := P
   | A ^= N
   |)
  where
    dreal X;
    boolean B;
    statevar dreal S init 5.5;
    shared dreal P init 6.5;
  end;
