process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(2) | I ^= N | iterate I of B := B[?] next I : true end | Y := N
   |)
  where
    integer ZN, N;
    [2] integer I, B;
  end;
