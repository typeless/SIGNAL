process P =
  ( ? event START;
    ! integer COUNT; )
  pragmas
    Machine "lm3s6965evb"
    Boot {START}
  end pragmas
  (| COUNT := 1 when START |);
