process P =
  ( ? event START;
    ! integer COUNT; )
  pragmas
    Machine "mps2-an385"
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| COUNT := 1 when START |);
