process ITERATECARRIEDLONG =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := indices(2)
   | iterate K of (| Q := E[?] | E := Q |) with E := long(5) end
   | Q ^= N
   | W :: write("q=", long(Q) when N < 3)
   |)
  where
    integer ZN;
    long Q, E;
    [2] integer K;
    label W;
  end;
