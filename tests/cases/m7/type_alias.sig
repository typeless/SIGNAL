process ALIAS =
  ( ! ushort H; )
  (| H := ZH + ushort(32768)
   | ZH := H $
   |)
  where
    type word = ushort;
    word ZH;
  end;
