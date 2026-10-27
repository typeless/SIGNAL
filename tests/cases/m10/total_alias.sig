process TOTALALIAS =
  ( ! integer A; )
  (| A := 1 |)
  where
    type ROW = [65536] boolean;
    [32768] ROW R;
  end;
