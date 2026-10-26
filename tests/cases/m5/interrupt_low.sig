process P =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
