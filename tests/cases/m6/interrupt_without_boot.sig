process P =
  ( ? event TICK;
    ! integer COUNT; )
  pragmas
    Machine "mps2-an385"
    Interrupt {TICK} "15"
  end pragmas
  (| COUNT := ZCOUNT + 1
   | ZCOUNT := COUNT $ init 0
   | COUNT ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
