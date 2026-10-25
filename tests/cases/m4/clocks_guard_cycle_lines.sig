process GL =
  ( ! integer N, K, J; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | on HH ::
       (| J := 7
        | HG := ^J
        |)
   | on HG ::
       (| K := 7
        | HH := ^K
        |)
   |)
  where
    integer ZN;
    event HG, HH;
  end;
