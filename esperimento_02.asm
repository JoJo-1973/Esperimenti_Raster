!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>
!source <system/6510_tools.asm>
!source <system/raster_tools.asm>

__KERNAL_STATUS = "DISABLED"
LINE1 = 103

  +BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #2"

START:
  jmp MAIN

IRQ1:
  +Enter_Raster_IRQ "STABLE", LINE1
  nop                           ; 3   (+2)
  nop                           ; 5   (+2)
  cmp UNUSED                    ; 7   (+3)

  lda #VIC_WHITE                ; 11  (+2)
  sta BGCOL0                    ; 13  (+4)
  lda #VIC_BLUE                 ; 17  (+2)
  sta BGCOL0                    ; 19
  +Next_Raster_IRQ "STABLE", LINE1, IRQ1, "SLOW"

MAIN:
  lda #VIC_BLUE
  sta EXTCOL
  sta BGCOL0

  +Init_Raster_System $FB
  +Start_Raster_IRQ "STABLE", LINE1, IRQ1

  !if __KERNAL_STATUS = "DISABLED" {
    inc VICSCN
    jmp *-3
  } else {
    rts
  }
