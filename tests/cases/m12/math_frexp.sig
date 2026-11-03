process MATHFREXP =
  ( ? dreal X;
    ! dreal M; integer E; )
  (| (M, E) := frexp(X)
   |)
  where
  end;
