process ENUMEXPR =
  ( ? integer I;
    ! integer A, B, C; [3] integer V; )
  (| V := [I, I + 1, 7]
   | A := V[0]
   | B := V[1]
   | C := V[2]
   |)
  where
  end;
