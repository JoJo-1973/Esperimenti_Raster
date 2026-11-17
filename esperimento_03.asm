; ESPERIMENTO DI RASTER #3: 16 linee di raster colorate nel bordo ottenute con un'interruzione stabilizzata. Soluzione implementata con le macro di raster_tools.asm.
; E' una replica di quanto fatto in ready64_04.asm.

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_esperimento_03.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>
!source <chip/6510_tools.asm>
!source <chip/raster_tools.asm>

RASTER_START  = 30
RASTER_HEIGHT = 16

BASIC_START         = BASTXT

*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #3"

START:
  jmp MAIN
!source <chip/vic_ii_tools.asm>

!align 255,0,0                  ; Allinea il gestore delle interruzioni alla pagina.
; [MAPPA: Gestore IRQ a LINE1]
IRQ1:
  +m_Enter_Raster_IRQ "STABLE", RASTER_START-1

.Waste_Line:
  +m_Raster_Grip                  ; 03 (+7)   Queste istruzioni servono a bruciare cicli
                                ;           in modo che le 3 istruzioni che seguono
  +m_Delay_5n1 ".X", 7            ; 10 (+36)  l'etichetta '.Fill_Line' terminino la loro
  cmp UNUSED                    ; 46 (+3)   esecuzione ESATTAMENTE al ciclo 62 (+eventuali NTSC).
                                ;           Se i calcoli sono giusti il cambio di colore avverrà
                                ;           precisamente all'inizio della linea successiva, e così
                                ;           per tutte le altre rasterline successive.

  ldy #RASTER_HEIGHT            ; 49 (+2)

.Fill_Line:
  tya                           ; 51 (+2)
  eor #$FF                      ; 53 (+2)
  clc                           ; 55 (+2)
  adc #17                       ; 57 (+2)
  sta EXTCOL                    ; 59 (+4)

  +m_Raster_Grip                  ; 00 (+7)

  +m_Delay_5n1 ".X", 7            ; 07 (+36)
  cmp UNUSED                    ; 43 (+3)

  dey                           ; 46 (+2)
  bne .Fill_Line                ; 48 (+3)

  cmp UNUSED                    ; 50 (+3)
  nop                           ; 53 (+2)
  nop                           ; 55 (+2)

  lda #VIC_BLUE           ; 57 (+2)
  sta EXTCOL                    ; 59 (+4)

  +m_Next_Raster_IRQ "STABLE", RASTER_START-1, IRQ1, "SLOW" ; Almeno uno dei gestori di interruzione nella catena deve occuparsi della scansione della tastiera.

PALETTE:
  !byte VIC_BLUE,VIC_BLUE,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT

MAIN:
  lda #<PALETTE
  ldx #>PALETTE
  jsr VIC_PALETTE

  +m_Init_Raster_System    ; Inizializza la catena delle interruzioni
  +m_Start_Raster_IRQ "STABLE", RASTER_START-1, IRQ1

  !if __DISABLE_KERNAL = 1 {
    inc VICSCN                  ; Un semplice effetto per mostrare che il computer non si blocca quando il Kernal è disabilitato.
    jmp *-3
  } else {
    rts
  }
