process P =
  ( ! integer Y; [2] integer B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := A | A := indices(2) | Y := N
   |)
  where
    integer ZN, N;
    [2] integer A;
  end;
