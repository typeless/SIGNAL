process ELEMENTLABEL =
  ( ? integer I;
    ! integer A, B; )
  (| L :: A := I + 1
   | B := I * 2
   | L[0] --> B
   |)
  where
    label L;
  end;
