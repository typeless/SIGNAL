process P =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Boot {START}
    Interrupt {TICK} "27"
    Interrupt {TICK} "28"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
