process WIDENHOLDCOMPLEX =
  ( ? integer N; dcomplex A;
    ! dcomplex Y1, Y2, Y3, Y4, Y5; )
  (| X := A when N > 1
   | B := N > 0
   | Y1 := X cell B init K
   | Y2 := var X init K3
   | Y2 ^= N
   | S ::= X
   | Y3 := S? when B
   | P ::= A when N > 2
   | P ^= N
   | Y4 := P
   | Y5 := A $ 1 init K
   | A ^= N
   |)
  where
    dcomplex X;
    boolean B;
    constant complex K = 0.1 @ 2.5;
    constant complex K3 = 0.1 @ (-0.2);
    statevar dcomplex S init K;
    shared dcomplex P init (0.3 @ 0.5);
  end;
