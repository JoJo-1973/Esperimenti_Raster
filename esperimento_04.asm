; ESPERIMENTO DI RASTER #4: Riempi lo schermo di caratteri e fanne scrollare una parte mediante un'interruzione stabilizzata. Soluzione implementata con le macro di raster_tools.asm.

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_esperimento_04.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>
!source <chip/6510_tools.asm>
!source <chip/raster_tools.asm>


RASTER_START  = 51+(2*8)-1
RASTER_STOP   = RASTER_START+(15*8)

BASIC_START         = BASTXT

*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #4"

START:
  jmp MAIN
!source <chip/vic_ii_tools.asm>

XSCROLL:
  !byte 0

!align 255,0,0                  ; Allinea il gestore delle interruzioni alla pagina.
; [MAPPA: Gestore IRQ: Inizio dell'area di scorrimento]

SCROLL_START:
  +m_Enter_Raster_IRQ "STABLE", RASTER_START

  +m_Delay_5n1 ".Y", 4            ; 03 (+21)
  nop                           ; 24 (+2)
  nop                           ; 26 (+2)
  +m_Raster_Grip                  ; 28 (+7)

  dec XSCROLL                   ; 35 (+6)
  bpl .Waste                    ; 41 (+2)  A partire da questo punto il codice si biforca: un ramo viene eseguito se XSCROLL è maggiore di zero (Ramo "B")
  lda #7                        ; 43 (+2) mentre l'altro viene eseguito se XSCROLL scende sotto lo zero e dev'essere ripristinato al valore di 7 (Ramo "A").
  sta XSCROLL                   ; 45 (+4) E' fondamentale che entrambi i rami consumino lo stesso numero di cicli, pertanto il ramo che "non fa niente"
                                ; viene dirottato verso istruzioni "inutili" per poi ricongiungersi al flusso principale. Il bilancio è calcolato così:
                                ; Ramo "A": bpl non preso (+2); lda (+2); sta (+4). Totale: 8 cicli.
                                ; Ramo "B": bpl preso (+3); nop (+2); jmp di ricongiungimento (+3). Totale: 8 cicli.
                                ; Entrambi i rami partono a 41 cicli e si ricongiungono a 49 cicli. E' quindi fondamentale che la routine non attraversi confini di pagina perché questo aggiungerebbe cicli all'istruzione bpl.
.Update:
  lda SCROLX                    ; 49 (+4)
  and #%11111000                ; 53 (+2)
  ora XSCROLL                   ; 55 (+4)
  sta SCROLX                    ; 59 (+4) La scrittura di SCROLX avviene esattamente al ciclo 62.
  bne .Done

.Waste:                         ; 43 (+1)
  nop                           ; 44 (+2)
  jmp .Update                   ; 46 (+3)

.Done:
  +m_Next_Raster_IRQ "STABLE", RASTER_STOP, SCROLL_STOP, "FAST"

; [MAPPA: Gestore IRQ: Arresto dell'area di scorrimento]
SCROLL_STOP:
  +m_Enter_Raster_IRQ "STABLE", RASTER_STOP

  +m_Delay_5n1 ".Y", 8            ; 03 (+41)
  nop                           ; 44 (+2)
  +m_Raster_Grip                  ; 46 (+7)
  lda SCROLX                    ; 53 (+4)
  and #%11111000                ; 57 (+2)
  sta SCROLX                    ; 59 (+4) La scrittura di SCROLX avviene esattamente al ciclo 62.

  +m_Next_Raster_IRQ "STABLE", RASTER_START, SCROLL_START, "SLOW" ; Almeno uno dei gestori IRQ della catena deve occuparsi della scansione della tastiera.

PALETTE:
  !byte VIC_BLUE,VIC_BLUE,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_WHITE

MAIN:
  lda #<PALETTE
  ldx #>PALETTE
  jsr VIC_PALETTE

  jsr CLRSCR
  ldx #0

.Loop_Fill_Screen:
  txa

  sta VICSCN,x
  sta VICSCN+$100,x
  sta VICSCN+$200,x
  sta VICSCN+$2E8,x

  inx
  bne .Loop_Fill_Screen

  stx XSCROLL                   ; Inizializza XSCROLL

  lda SCROLX
  and #%11111000
  sta SCROLX

  +m_Init_Raster_System    ; Inizializza la catena delle interruzioni
  +m_Start_Raster_IRQ "STABLE", RASTER_START, SCROLL_START

  !if __DISABLE_KERNAL = 1 {
    inc VICSCN                  ; Un semplice effetto per mostrare che il computer non si blocca quando il Kernal è disabilitato.
    jmp *-3
  } else {
    rts
  }
