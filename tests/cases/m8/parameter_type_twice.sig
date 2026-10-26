process P =
  ( ! integer A; long B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := OUTER{integer}(N)
   | B := OUTER{long}(long(N) * long(100000))
   |)
  where
    integer ZN, N;
    process OUTER = { type RES; } ( ? RES X; ! RES Y; ) (| Y := INNER{RES}(X) |)
      where
        process INNER = { type RES; } ( ? RES X; ! RES Y; ) (| Y := X * X |);
      end;
  end;
