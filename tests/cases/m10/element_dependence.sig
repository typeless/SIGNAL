process ELEMENTDEPENDENCE =
  ( ? integer I;
    ! integer A, B, C; )
  (| A := I + 1
   | X := V next I : A
   | B := X[0] + A
   | C := B + 1
   | X[I] --> B
   | A --> X[I + 1] --> C
   |)
  where
    [3] integer X;
    constant [3] integer V = [5, 6, 7];
  end;
