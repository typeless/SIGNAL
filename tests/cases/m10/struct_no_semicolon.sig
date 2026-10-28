process STRUCTNOSEMICOLON =
  ( ? integer N;
    ! integer O; )
  (| S := (N, N * 10)
   | O := S.A + S.B
   |)
  where
    struct (integer A; integer B) S;
  end;
