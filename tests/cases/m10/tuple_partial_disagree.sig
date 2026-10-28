process TUPLEPARTIALDISAGREE =
  ( ! integer N, X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N modulo 3
   | case K in
       {1}: (U, V) ::= (N * 10, N)
     end
   | case K in
       {2}: (U, V) ::= (N * 100, -N)
       else (U, V) ::= (0, 0) when ^N
     end
   | U ^= N
   | V ^= N
   | X := U
   | Y := V
   |)
  where
    integer ZN, K;
    shared integer U, V;
  end;
