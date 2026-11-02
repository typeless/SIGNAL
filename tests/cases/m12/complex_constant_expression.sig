process COMPLEXCONSTANTEXPRESSION =
  ( ! complex Z; )
  (| Z := K
   |)
  where
    constant complex K = (1.0 @ 2.0) * (1.0 @ 2.0);
  end;
