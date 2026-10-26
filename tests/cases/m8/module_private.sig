module TIMERS =
  private constant integer TICK = 3;
  constant integer TOCK = 4;
end;
process P =
  ( ! integer A; )
  (| A := ZA + TOCK + TICK
   | ZA := A $ init 0
   |)
  where
    use TIMERS;
    integer ZA;
  end;
