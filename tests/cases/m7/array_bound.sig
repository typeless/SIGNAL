process P =
  ( ! integer S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | array I to N of (| Q := Q[?] next I : I * 2 |) end
   | S := N + Q[3]
   |)
  where
    integer ZN, N;
    [8] integer Q;
  end;
