process SHARED =
  ( ? event START, TICK;
    ! integer N; )
  pragmas
    Boot {START}
    Interrupt {TICK} "27"
  end pragmas
  (| N := 1 when START
   | START ^= TICK
   |);
