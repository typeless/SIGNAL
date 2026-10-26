process ROWS =
  ( ! integer S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S := R[N modulo 4]
   |)
  where
    type row = [4] integer;
    constant row R = [10, 20, 30, 40];
    integer ZN, N;
  end;
