process PARTIALUNSHARED =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N modulo 3
   | case K in
       {1}: X ::= N * 10
       {2}: X ::= N * 100
       else X ::= 0
     end
   | X ^= N
   | Y := X
   |)
  where
    integer ZN, K; integer X;
  end;
