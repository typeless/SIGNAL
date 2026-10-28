process INPUTLONGLINE =
  ( ? [2, 3] long V; long K;
    ! [2, 3] long W; long S; )
  (| W := V
   | S := K
   | V ^= K
   |);
