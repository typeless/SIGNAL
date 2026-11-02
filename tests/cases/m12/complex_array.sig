process COMPLEXARRAY =
  ( ? complex A, B; integer I;
    ! [2] complex T, U; complex E; )
  (| T := [A, B]
   | U := T next I : A * B
   | E := U[1 - I]
   | A ^= I
   |)
  where
  end;
