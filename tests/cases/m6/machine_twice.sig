process P =
  ( ? event START;
    ! integer TALLY; )
  pragmas
    Machine "mps2-an385"
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| TALLY := 1 when START |);
