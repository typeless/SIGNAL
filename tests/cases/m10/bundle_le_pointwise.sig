process BUNDLELEPOINTWISE =
  ( ? integer N;
    ! bundle (boolean P; boolean Q;) L, M; )
  (| E := N modulo 2 = 0
   | X := (N when E, N + 1)
   | Y := (3 when ^N when E, 2 when ^N)
   | L := X <<= Y
   | M := X == Y
   |)
  where
    boolean E;
    bundle (integer P; integer Q;) X, Y;
  end;
