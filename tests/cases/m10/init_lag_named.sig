process INITLAGNAMED =
  ( ! integer N, T; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S := N $ 2
   | T := S
   |)
  where
    integer ZN;
    integer S init Z;
    constant [2] integer Z = [5, 6];
  end;
