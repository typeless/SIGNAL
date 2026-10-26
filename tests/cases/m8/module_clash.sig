module FIRST =
  constant integer K = 1;
end;
module SECOND =
  constant integer K = 2;
end;
process P = ( ! integer A; ) (| A := ZA + 1 | ZA := A $ init 0 |) where integer ZA; end;
