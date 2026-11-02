process REALMPS2 =
  ( ? event START;
    ! integer N; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| N := 1 when START
   |)
  where
    real X;
  end;
