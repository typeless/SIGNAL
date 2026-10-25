process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(2) | I ^= N | iterate I of A := (N+1)[?] end | Y := A
   |)
  where
    integer ZN, N;
    [2] integer I; integer A;
  end;
