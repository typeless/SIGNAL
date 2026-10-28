process STRUCTSCALARTWICE =
  ( ? integer N;
    ! integer O; )
  (| S := (N, N)
   | O := S.A
   |)
  where
    struct (integer A; integer B;) S;
    integer S;
  end;
