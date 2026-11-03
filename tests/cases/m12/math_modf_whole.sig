process MATHMODFWHOLE =
  ( ? dreal X;
    ! dreal F, I; )
  (| (F, I) := modf(X) + 1.0
   |)
  where
  end;
