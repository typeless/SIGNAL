process NESTEDSTRUCT =
  ( ? integer N;
    ! integer P, Q, R, S, T; )
  (| X.A.BC := N + 1
   | X.A.B := N + 2
   | X.AB.C := N + 3
   | X.AB.D.E.F := N + 4
   | Y := X
   | Z := X.AB
   | P := Y.A.BC
   | Q := Y.A.B
   | R := Y.AB.C
   | S := Z.D.E.F
   | T := X.AB.D.E.F * 10
   |)
  where
    type INNER = struct (integer C; struct (struct (integer F;) E;) D;);
    struct (struct (integer BC; integer B;) A; INNER AB;) X, Y;
    INNER Z;
  end;
