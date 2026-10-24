process W =
  ( ! integer N, K, J; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | on HG :: (| K := 7 | HH := ^K | on HH :: (| J := 7 | HG := ^J |) |)
   |)
  where
    integer ZN;
    event HG, HH;
  end;
