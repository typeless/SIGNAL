process EXTBCAST =
  ( ? [2, 2] short M; short K;
    ! [2, 2] short P, Q; [2, 2] boolean R; [2, 2] short S; )
  (| P := M * K
   | Q := K - M
   | R := M >= K
   | S := if M > K then M else K
   |);
