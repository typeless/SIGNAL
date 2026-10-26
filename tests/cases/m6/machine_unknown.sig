process P =
  ( ? event START;
    ! integer TALLY; )
  pragmas
    Machine "lm3s6965evb"
    Boot {START}
  end pragmas
  (| TALLY := 1 when START |);
