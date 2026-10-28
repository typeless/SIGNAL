process STRUCTALIASTWICENESTED =
  ( ? integer N;
    ! integer O, Q; )
  (| P := (N, N + 1)
   | O := P.X
   | Q := F(N)
   |)
  where
    type POINT = struct (integer X; integer Y;);
    POINT P;
    function F = ( ? integer I; ! integer R; )
      (| W := (I, I * 10) | R := W.X |)
      where
        type POINT = struct (integer Y; integer X;);
        POINT W;
      end;
  end;
