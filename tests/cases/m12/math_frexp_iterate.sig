process MATHFREXPITERATE =
  ( ? [4] dreal X;
    ! [4] dreal M, F, I; [4] integer E; )
  (| array K to 3 of
       (M[K], E[K]) := frexp(X[K])
     end
   | array J to 3 of
       (F[J], I[J]) := modf(X[J])
     end
   |)
  where
  end;
