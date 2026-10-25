process P =
  ( ? event TICK;
    ! integer COUNT; )
  pragmas
    Interrupt {TICK} "27"
  end pragmas
  (| COUNT := ZCOUNT + 1
   | ZCOUNT := COUNT $ init 0
   | COUNT ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
