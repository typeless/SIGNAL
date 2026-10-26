module TIMERS =
  process CMSDK_TIMER = ( ? integer X; ! integer Y; ) (| Y := X + 1 |);
end;
process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := CMSDK_TIMER(N)
   |)
  where
    integer ZN, N;
  end;
