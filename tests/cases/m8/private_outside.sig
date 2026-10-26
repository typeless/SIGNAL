process P = ( ! integer A; ) (| A := ZA + K | ZA := A $ init 0 |)
  where
    integer ZA;
    private constant integer K = 1;
  end;
