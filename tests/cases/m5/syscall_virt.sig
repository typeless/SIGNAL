process P =
  ( ? event START, TICK;
    ! integer COUNT; )
  pragmas
    Boot {START}
    Interrupt {TICK} "27"
  end pragmas
  (| COUNT := ZCOUNT + 1
   | ZCOUNT := COUNT $ init 0
   | COUNT ^= TICK
   | DONE := syscall{OS}(1, 0 when TICK, 0, 0, 0, 0, 0)
   |)
  where
    type OS = external;
    integer ZCOUNT;
    long DONE;
  end;
