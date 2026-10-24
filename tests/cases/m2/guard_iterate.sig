process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(2)
   | on when N = 1 :: (| iterate I of A := A[?] + I with A := 0 end |)
   | Y := A
   |)
  where
    integer ZN, N;
    [2] integer I; integer A;
  end;
