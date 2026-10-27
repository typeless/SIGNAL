process PARTIALTUPLE =
  ( ! integer N, X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | (X, Y) ::= SPLIT(N)
   |)
  where
    integer ZN;
    function SPLIT = ( ? integer A; ! integer B, D; ) (| B := A | D := A |);
  end;
