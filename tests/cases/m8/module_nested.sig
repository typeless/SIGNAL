module OUTER =
  constant integer K = 1;
  module INNER =
    constant integer J = 2;
  end;
end;
process P = ( ! integer A; ) (| A := ZA + K | ZA := A $ init 0 |) where use OUTER; integer ZA; end;
