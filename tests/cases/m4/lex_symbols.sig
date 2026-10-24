process SYMBOLS =
  ( ! integer S, Y; )
  (|N:=ZN+1|ZN:=N$init 0|X:=0..N-1|iterate X of S:=S[?]+X with S:=0 end|Y:=N*2|Y-->S|)
  where
    integer ZN, N;
    [4] integer X;
  end;
