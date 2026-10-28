process STRUCTDEPTH =
  ( ? integer N; ! integer T; )
  (| X.A.B.C.D.E := N
   | T := X.A.B.C.D.E
   |)
  where
    struct (struct (struct (struct (struct (integer E;) D;) C;) B;) A;) X;
  end;
