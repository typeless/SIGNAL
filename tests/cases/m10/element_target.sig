process ELEMENTTARGET =
  ( ! [2, 3] integer T; [3] integer V; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | array I to 1 of
       array J to 2 of
         T[I, J] := I * 10 + J + N
       end
     end
   | array K to 2 of
       V[K] := K * K * N
     end
   |)
  where
    integer N, ZN;
  end;
