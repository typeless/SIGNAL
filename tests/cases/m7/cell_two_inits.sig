process P =
  ( ? integer N; ! integer Y init 7; )
  (| X := N when (N modulo 4 = 0)
   | C := (N modulo 3 = 0) when (N modulo 2 = 1)
   | Y := X cell C init 5
   |)
  where
    integer X;
    boolean C;
  end;
