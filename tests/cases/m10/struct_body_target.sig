process STRUCTBODYTARGET =
  ( ? integer N;
    ! integer O; )
  (| array I to 2 of
       S := MK(N + I)
     end
   | O := S.A + S.B * 10
   |)
  where
    struct (integer A; integer B;) S;
    function MK = ( ? integer X; ! struct (integer A; integer B;) R; ) (| R := (X, X * 2) |);
  end;
