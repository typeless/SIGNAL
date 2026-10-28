process STRUCTELEMENTTARGET =
  ( ? integer N;
    ! integer O; [3] integer V; )
  (| array I to 2 of
       M[I] := (N + I, N * I)
     end
   | array J to 2 of
       V[J] := M[J].A + M[J].B
     end
   | O := size(M)
   |)
  where
    [3] struct (integer A; integer B;) M;
  end;
