process ORDER =
  ( ! integer A, B; )
  (| I := indices(8)
   | iterate I of
       (| A := A[?] + Q[?]
        | Q := Q[?] + 1
        | B := B[?] + Q
        |)
     with (| Q := 0 | A := 0 | B := 0 |)
     end
   |)
  where
    integer Q;
    [8] integer I;
  end;
