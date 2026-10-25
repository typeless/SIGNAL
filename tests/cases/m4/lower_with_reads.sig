process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(2) | I ^= N | iterate I of A := A[?] + 1 with A := A end | Y := A
   |)
  where
    integer ZN, N;
    [2] integer I; integer A;
  end;
