process ENUMFROMINT =
  ( ! integer K; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := color(N)
   | K := integer(C)
   |)
  where
    type color = enum (red, green);
    integer ZN, N;
    color C;
  end;
