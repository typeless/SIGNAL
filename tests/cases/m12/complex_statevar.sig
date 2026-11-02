process COMPLEXSTATEVAR =
  ( ? integer N; complex A;
    ! complex Y, Z; dcomplex V; )
  (| C := N modulo 2 = 0
   | CNT ::= (CNT? * A) when C
   | Y := CNT? when N > 0
   | Z := (CNT? + A) when not C default (K when N > 0)
   | DS ::= (DS? + A) when C
   | V := DS? when N > 0
   | A ^= N
   |)
  where
    boolean C;
    statevar complex CNT init K;
    statevar dcomplex DS init K;
    constant complex K = 1.0 @ 1.0;
  end;
