process P =
  ( ! integer S; )
  (| N := ZN + 1 | ZN := N $ init 0
   | array I to 2 of (| Q := Q[?] next I : I * 2 |) end
   | S := N + Q[2]
   |)
  where integer ZN, N; [4] integer Q; end;
