process DIMUSER =
  ( ? integer I;
    ! integer A; )
  (| A := dim(I) |)
  where
    process dim = ( ? integer X; ! integer Y; ) (| Y := X + 1 |);
  end;
