process P =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Boot {START}
    Interrupt {TICK, START} "27"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
