process STRUCTPARTIALDISAGREE =
  ( ! integer N, X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N modulo 3
   | case K in
       {1}: S ::= (N * 10, N)
     end
   | case K in
       {1, 2}: S ::= (N * 100, -N)
       else S ::= (0, 0) when ^N
     end
   | S.A ^= N
   | (X, Y) := S
   |)
  where
    integer ZN, K;
    shared struct (integer A; integer B;) S;
  end;
