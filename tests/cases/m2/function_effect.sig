process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := PEEK(N)
   |)
  where
    integer ZN, N;
    type MEM = external;
    function PEEK = ( ? integer X; ! long B; ) (| B := load{MEM, long}(pointer(ulong(X))) |);
  end;
