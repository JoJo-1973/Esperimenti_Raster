!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>
!source <system/6510_tools.asm>
!source <system/raster_tools.asm>

__KERNAL_STATUS = "ENABLED"

RASTER_START  = 51+(2*8)-1
RASTER_STOP   = RASTER_START+(15*8)

  +BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #4"

START:
  jmp MAIN

XSCROLL:
  !byte 0

SCROLL_START:
  +Enter_Raster_IRQ "STABLE", RASTER_START

  +Delay_5n1 ".Y", 4            ; 03 (+21)
  nop                           ; 24 (+2)
  nop                           ; 26 (+2)
  +Raster_Grip                  ; 28 (+7)

  dec XSCROLL                   ; 35 (+6)
  bpl .Waste                    ; 41 (+2)

  lda #7                        ; 43 (+2)
  sta XSCROLL                   ; 45 (+4)

.Update:
  lda SCROLX                    ; 49 (+4)
  and #%11111000                ; 53 (+2)
  ora XSCROLL                   ; 55 (+4)
  sta SCROLX                    ; 59 (+4)
  bne .Done

.Waste:                         ; 43 (+1)
  nop                           ; 44 (+2)
  jmp .Update                   ; 46 (+3)

.Done:
  +Next_Raster_IRQ "STABLE", RASTER_STOP, SCROLL_STOP, "FAST"


SCROLL_STOP:
  +Enter_Raster_IRQ "STABLE", RASTER_STOP

  +Delay_5n1 ".Y", 8            ; 03 (+41)
  nop                           ; 44 (+2)
  +Raster_Grip                  ; 46 (+7)
  lda SCROLX                    ; 53 (+4)
  and #%11111000                ; 57 (+2)
  sta SCROLX                    ; 59 (+4)

  +Next_Raster_IRQ "STABLE", RASTER_START, SCROLL_START, "SLOW"

MAIN:
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

  stx XSCROLL

  lda SCROLX
  and #%11111000
  sta SCROLX

  +Init_Raster_System $FB
  +Start_Raster_IRQ "STABLE", RASTER_START, SCROLL_START

  !if __KERNAL_STATUS = "DISABLED" {
    inc VICSCN
    jmp *-3
  } else {
    rts
  }
