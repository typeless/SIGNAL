process STRUCTSCALARTWICEKNOWN =
  ( ? integer N;
    ! integer O; )
  (| S := N
   | O := S
   |)
  where
    integer S;
    struct (integer A; integer B;) S;
  end;
