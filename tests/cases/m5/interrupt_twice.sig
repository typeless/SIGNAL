process P =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Interrupt {START} "27"
    Interrupt {TICK} "27"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
