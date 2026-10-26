process P =
  ( ? event START, TICK, RESET;
    ! integer TALLY; )
  pragmas
    Boot {START}
    Interrupt {TICK} "27"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
