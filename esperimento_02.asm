; ESPERIMENTO DI RASTER #2: Una colorazione parziale di una linea di raster ottenuta con un'interruzione stabilizzata. Soluzione implementata con le macro di raster_tools.asm.

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_esperimento_02.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>
!source <chip/6510_tools.asm>
!source <chip/raster_tools.asm>

LINE1 = 103

BASIC_START         = BASTXT

*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #2"

START:
  jmp MAIN
!source <chip/vic_ii_tools.asm>

!align 255,0,0                  ; Allinea il gestore delle interruzioni alla pagina.
; [MAPPA: Gestore IRQ a LINE1]
IRQ1:
  +m_Enter_Raster_IRQ "STABLE", LINE1         ; Colora parzialmente la linea di raster in bianco
  nop                           ; 3   (+2)
  nop                           ; 5   (+2)
  cmp UNUSED                    ; 7   (+3)

  lda #VIC_WHITE                ; 11  (+2)
  sta BGCOL0                    ; 13  (+4)
  lda #VIC_BLUE                 ; 17  (+2)
  sta BGCOL0                    ; 19
  +m_Next_Raster_IRQ "STABLE", LINE1, IRQ1, "SLOW" ; Almeno uno dei gestori di interruzione nella catena deve occuparsi della scansione della tastiera.


PALETTE:
  !byte VIC_BLUE,VIC_BLUE,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT

MAIN:
  lda #<PALETTE
  ldx #>PALETTE
  jsr VIC_PALETTE

  +m_Init_Raster_System   ; Inizializza la catena delle interruzioni
  +m_Start_Raster_IRQ "STABLE", LINE1, IRQ1

  !if __DISABLE_KERNAL = 1 {
    inc VICSCN                  ; Un semplice effetto per mostrare che il computer non si blocca quando il Kernal è disabilitato.
    jmp *-3
  } else {
    rts
  }
