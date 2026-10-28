process TUPLEPARTIAL =
  ( ! integer N, X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N modulo 3
   | T := (N * 100, -N)
   | case K in
       {1}: S ::= (N * 10, N)
       {2}: S ::= T
       else (S.A, S.B) ::= (0, 0) when ^N
     end
   | S.A ^= N
   | (X, Y) := S
   |)
  where
    integer ZN, K;
    struct (integer A; integer B;) T;
    shared struct (integer A; integer B;) S;
  end;
