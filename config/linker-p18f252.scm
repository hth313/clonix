(define memories
  '((memory flash (address (#x0 . #x7fff))
            (section (reset #x0) (interrupt #x0008)
                     (code  Mapping #x0100)
                     (Upper0 #x0800) (Lower0 #x2000)
                     (Upper1 #x0c00) (Lower1 #x3000)
                     (Upper2 #x1000) (Lower2 #x4000)
                     (Upper3 #x1400) (Lower3 #x5000)
                     (Upper4 #x1800) (Lower4 #x6000)
                     (Upper5 #x1c00) (Lower5 #x7000)
                     )
            )
    (memory RAM (address (#x0 . #x2ff))
            (section variables))
    (memory config (address (#x300000 . #x300007))
            (section config))
    (memory eeprom (address (#xf00000 . #xf000ff))
            (section EEPROM))
    ))
