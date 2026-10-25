process P =
  ( ? event START, TICK;
    ! integer COUNT; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "14"
  end pragmas
  (| COUNT := ZCOUNT + 1
   | ZCOUNT := COUNT $ init 0
   | COUNT ^= TICK
   |)
  where
    integer ZCOUNT;
  end;
