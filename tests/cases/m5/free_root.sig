process P =
  ( ? event START, TICK;
    ! integer TALLY, STEPS; )
  pragmas
    Boot {START}
    Interrupt {TICK} "27"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   | STEPS := ZSTEPS + 1
   | ZSTEPS := STEPS $ init 0
   |)
  where
    integer ZCOUNT, ZSTEPS;
  end;
