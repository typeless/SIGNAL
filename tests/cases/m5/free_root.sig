process P =
  ( ? event START, TICK;
    ! integer COUNT, STEPS; )
  pragmas
    Boot {START}
    Interrupt {TICK} "27"
  end pragmas
  (| COUNT := ZCOUNT + 1
   | ZCOUNT := COUNT $ init 0
   | COUNT ^= TICK
   | STEPS := ZSTEPS + 1
   | ZSTEPS := STEPS $ init 0
   |)
  where
    integer ZCOUNT, ZSTEPS;
  end;
