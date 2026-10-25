process P =
  ( ? event START, TICK;
    ! integer COUNT; )
  pragmas
    Interrupt {START} "27"
    Interrupt {TICK} "27"
  end pragmas
  (| COUNT := ZCOUNT + 1
   | ZCOUNT := COUNT $ init 0
   | COUNT ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
