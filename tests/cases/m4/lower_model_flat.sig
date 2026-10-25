process P =
  ( ! integer Y; )
  (| Y := INNER() |)
  where
    process INNER =
      ( ! integer O; )
      (| N := ZN + 1
       | ZN := N $ init 0
       | O := N
       | O := ZN
       |)
      where integer ZN, N; end;
  end;
