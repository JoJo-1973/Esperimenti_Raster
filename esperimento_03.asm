!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>
!source <system/6510_tools.asm>
!source <system/raster_tools.asm>

__KERNAL_STATUS = "DISABLED"

RASTER_START  = 30
RASTER_HEIGHT = 16

  +BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #3"

START:
  jmp MAIN

IRQ1:
  +Enter_Raster_IRQ "STABLE", RASTER_START-1

.Waste_Line:
  +Raster_Grip                  ; 03 (+7)   Queste istruzioni servono a bruciare cicli
                                ;           in modo che le 3 istruzioni che seguono
  +Delay_5n1 ".X", 7            ; 10 (+36)  l'etichetta '.Fill_Line' terminino la loro
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

  +Raster_Grip                  ; 00 (+7)

  +Delay_5n1 ".X", 7            ; 07 (+36)
  cmp UNUSED                    ; 43 (+3)

  dey                           ; 46 (+2)
  bne .Fill_Line                ; 48 (+3)

  cmp UNUSED                    ; 50 (+3)
  nop                           ; 53 (+2)
  nop                           ; 55 (+2)

  lda #VIC_LIGHT_BLUE           ; 57 (+2)
  sta EXTCOL                    ; 59 (+4)

  +Next_Raster_IRQ "STABLE", RASTER_START-1, IRQ1, "SLOW"
                                ; Almeno uno dei gestori di interruzione nella catena
                                ; deve occuparsi della scansione della tastiera.

MAIN:
  +Init_Raster_System $FB
  +Start_Raster_IRQ "STABLE", RASTER_START-1, IRQ1

  !if __KERNAL_STATUS = "DISABLED" {
    inc VICSCN
    jmp *-3
  } else {
    rts
  }
