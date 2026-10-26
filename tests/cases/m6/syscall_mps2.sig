process P =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   | DONE := syscall{OS}(1, 0 when TICK, 0, 0, 0, 0, 0)
   |)
  where
    type OS = external;
    integer ZCOUNT;
    long DONE;
  end;
