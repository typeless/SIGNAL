process DCOMPLEXMPS2 =
  ( ? event START;
    ! integer N; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| N := 1 when START
   |)
  where
    constant dcomplex K = 1.0d0 @ 2.0d0;
  end;
