process RELINPUT =
  ( ? integer I; ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I ^< N
   |)
  where
    integer ZN;
  end;
