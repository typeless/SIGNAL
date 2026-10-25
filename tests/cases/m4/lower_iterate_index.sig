process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | iterate N of A := 1 end | Y := A
   |)
  where
    integer ZN, N;
    integer A;
  end;
