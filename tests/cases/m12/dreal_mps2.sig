process DREALMPS2 =
  ( ? event START;
    ! integer N; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| N := 1 when START
   | M := integer(1.5d0) when START
   |)
  where
    integer M;
  end;
