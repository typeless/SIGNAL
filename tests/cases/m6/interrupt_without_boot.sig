process P =
  ( ? event TICK;
    ! integer TALLY; )
  pragmas
    Machine "mps2-an385"
    Interrupt {TICK} "15"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
