process P =
  ( ? event TICK;
    ! integer TALLY; )
  pragmas
    Interrupt {TICK} "27"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
