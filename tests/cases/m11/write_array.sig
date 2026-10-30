process WRITEARRAY =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | write("e", V)
   |)
  where
    integer ZN;
    constant [2] integer V = [1, 2];
  end;
