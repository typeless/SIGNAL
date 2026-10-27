process IDTYPEASSERT =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N
   | assert (| X :=: (N > 1) |)
   |)
  where
    integer ZN;
  end;
