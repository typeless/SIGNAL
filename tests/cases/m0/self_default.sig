process SELFDEFAULT =
  ( ! integer N, S2, S3; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S2 := N default N
   | S3 := (S2 default S2) + N
   |)
  where
    integer ZN;
  end;
