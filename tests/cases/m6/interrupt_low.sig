process P =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "14"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
