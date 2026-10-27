process RESTRUCTURE =
  ( ? integer I; [2] integer S;
    ! [3] integer X, Y; )
  (| X := 2 : I
   | Y := P : S
   | S ^= I
   |)
  where
    constant [2] integer P = [2, 0];
  end;
