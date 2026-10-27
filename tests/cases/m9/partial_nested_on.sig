process P05 =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N modulo 3
   | H := when (N > 2)
   | case K in
       {1}: (| on H :: X ::= N * 10 |)
       {2}: X ::= N * 100
       else X ::= 0
     end
   | X ^= N
   | Y := X
   |)
  where
    integer ZN, K; event H; shared integer X;
  end;
