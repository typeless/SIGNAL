process P =
  ( ! integer N init -1; )
  (| N := M $
   | M := N + 1
   |)
  where
    integer M;
  end;
