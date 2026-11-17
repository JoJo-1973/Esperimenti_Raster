!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>
!source <system/6510_tools.asm>
!source <system/raster_tools.asm>

__KERNAL_STATUS = "ENABLED"

LINE1 = 100
LINE2 = LINE1+32
LINE3 = LINE2+32
LINE4 = LINE3+32

  +BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #1"

START:
  jmp MAIN

IRQ1:
  +Enter_Raster_IRQ "UNSTABLE", LINE1
  lda #VIC_RED
  sta EXTCOL
  sta BGCOL0
  +Next_Raster_IRQ "UNSTABLE", LINE2, IRQ2, "FAST"

IRQ2:
  +Enter_Raster_IRQ "UNSTABLE", LINE2
  lda #VIC_WHITE
  sta EXTCOL
  sta BGCOL0
  +Next_Raster_IRQ "UNSTABLE", LINE3, IRQ3, "FAST"

IRQ3:
  +Enter_Raster_IRQ "UNSTABLE", LINE3
  lda #VIC_GREEN
  sta EXTCOL
  sta BGCOL0
  +Next_Raster_IRQ "UNSTABLE", LINE4, IRQ4, "FAST"

IRQ4:
  +Enter_Raster_IRQ "UNSTABLE", LINE4
  lda #VIC_BLUE
  sta EXTCOL
  sta BGCOL0
  +Next_Raster_IRQ "UNSTABLE", LINE1, IRQ1, "SLOW"
                                ; Almeno uno dei gestori di interruzione nella catena
                                ; deve occuparsi della scansione della tastiera.
MAIN:
  lda #VIC_BLUE
  sta EXTCOL
  sta BGCOL0

  +Init_Raster_System $FB
  +Start_Raster_IRQ "UNSTABLE", LINE1, IRQ1

  !if __KERNAL_STATUS = "DISABLED" {
    inc VICSCN
    jmp *-4
  } else {
    rts
  }
