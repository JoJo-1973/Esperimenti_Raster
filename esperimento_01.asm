; ESPERIMENTO DI RASTER #1: Tre rasterbar ottenute con tre interruzioni non stabilizzate. Soluzione implementata con le macro di raster_tools.asm.

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_esperimento_01.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>
!source <chip/6510_tools.asm>
!source <chip/raster_tools.asm>


LINE1 = 100
LINE2 = LINE1+32
LINE3 = LINE2+32
LINE4 = LINE3+32

BASIC_START         = BASTXT

*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #1"

START:
  jmp MAIN

!source <chip/vic_ii_tools.asm>

!align 255,0,0                  ; Allinea i gestori delle interruzioni alla pagina.
; [MAPPA: Gestore IRQ a LINE1]
IRQ1:
  +m_Enter_Raster_IRQ "UNSTABLE", LINE1     ; Rasterbar rossa
  lda #VIC_RED
  sta EXTCOL
  sta BGCOL0
  +m_Next_Raster_IRQ "UNSTABLE", LINE2, IRQ2, "FAST"

; [MAPPA: Gestore IRQ a LINE2]
IRQ2:
  +m_Enter_Raster_IRQ "UNSTABLE", LINE2     ; Rasterbar bianca
  lda #VIC_WHITE
  sta EXTCOL
  sta BGCOL0
  +m_Next_Raster_IRQ "UNSTABLE", LINE3, IRQ3, "FAST"

; [MAPPA: Gestore IRQ a LINE3]
IRQ3:
  +m_Enter_Raster_IRQ "UNSTABLE", LINE3     ; Rasterbar verde
  lda #VIC_GREEN
  sta EXTCOL
  sta BGCOL0
  +m_Next_Raster_IRQ "UNSTABLE", LINE4, IRQ4, "FAST"

; [MAPPA: Gestore IRQ a LINE4]
IRQ4:
  +m_Enter_Raster_IRQ "UNSTABLE", LINE4     ; Chiudi le rasterbar e ricominciala catena di interruzioni
  lda #VIC_BLUE
  sta EXTCOL
  sta BGCOL0
  +m_Next_Raster_IRQ "UNSTABLE", LINE1, IRQ1, "SLOW" ; Almeno uno dei gestori di interruzione nella catena deve occuparsi della scansione della tastiera.

PALETTE:
  !byte VIC_BLUE,VIC_BLUE,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_TRANSPARENT

MAIN:
  lda #<PALETTE
  ldx #>PALETTE
  jsr VIC_PALETTE

  +m_Init_Raster_System                           ; Inizializza la catena delle interruzioni
  +m_Start_Raster_IRQ "UNSTABLE", LINE1, IRQ1

  !if __DISABLE_KERNAL = 1 {
    inc VICSCN                  ; Un semplice effetto per mostrare che il computer non si blocca quando il Kernal è disabilitato.
    jmp *-4
  } else {
    rts
  }
