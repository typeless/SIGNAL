process ENUMNESTED =
  ( ? integer I;
    ! [2, 3] integer M; integer A; )
  (| M := [[I, 1, 2], [3, I * 2, I - 1]]
   | A := M[1, 1] + M[0][2]
   |)
  where
  end;
