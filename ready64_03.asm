; ==============================================================================
; FILE:           ready64_03.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esercizio di raster #3: genera un'interruzione su più linee di
;                 raster consecutive (una rasterbar di 16 linee): primo
;                 approccio, fallimentare. Il codice di avvio installa il
;                 gestore IRQ e ritorna al BASIC. Codice originale di 0scur0,
;                 riadattato secondo le convenzioni di stile: del codice
;                 originale sono stati alterati solo i commenti e i nomi delle
;                 etichette e dei simboli. Articolo originale:
;                 https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster
; CONTENUTO:      IRQ_RASTERBAR   Gestore IRQ: disegna la rasterbar
; DIPENDENZE:     "config_ready64_03.asm"
;                 <c64/symbols.asm>
;                 <chip/cia.asm>
;                 <chip/vic_ii.asm>
;                 <system/standard.asm>
; REQUISITI ZP:   _COUNTER
; ==============================================================================

; ------------------------------------------------------------------------------
; Uscita e processore
; ------------------------------------------------------------------------------

!to "ready64 03.prg", cbm
!cpu 6510
!sl "ready64_03.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_ready64_03.asm", once

; ------------------------------------------------------------------------------
; Simboli
; ------------------------------------------------------------------------------

!source <c64/symbols.asm>, once
!source <chip/cia.asm>, once
!source <chip/vic_ii.asm>, once

; ------------------------------------------------------------------------------
; Mappa di memoria
; ------------------------------------------------------------------------------

BASIC_START         = BASTXT

; ($0801-$0825) Preambolo BASIC
; ($0826-$084D) Codice principale
; ($084E-$086B) Gestore IRQ della rasterbar

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

RASTER_LINE         = 16        ; Linea video della prima interruzione
ROWS                = 16        ; Altezza della rasterbar
_COUNTER            = UNUSED    ; Contatore di linea

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESERCIZIO DI RASTER #3"

; [MAPPA: Codice principale]
START:
  sei

  lda #(ROWS-1)                 ; Inizializza il contatore di riga.
  sta _COUNTER

  lda #<IRQ_RASTERBAR           ; Imposta il nuovo gestore IRQ.
  sta CINV
  lda #>IRQ_RASTERBAR
  sta CINV+1

  lda #RASTER_LINE              ; Imposta la linea della prima IRQ.
  sta RASTER
  lda SCROLY
  and #%01111111
  sta SCROLY

  lda #%00000001                ; Il raster è l'unica sorgente di IRQ del VIC.
  sta IRQMSK

  lda #%01111111                ; Disabilita le IRQ provenienti dal CIA 1.
  sta CIAICR

  cli

.Exit_START:
  rts

; ------------------------------------------------------------------------------
; Subroutine del codice
; ------------------------------------------------------------------------------

; [MAPPA: Gestore IRQ della rasterbar]
; ==============================================================================
; SUBROUTINE: IRQ_RASTERBAR
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ della rasterbar: a ogni interruzione incrementa il
;               colore del bordo e sposta l'interruzione alla linea successiva.
;               Quando ha disegnato ROWS linee, reinizializza il contatore di
;               riga, ripristina il colore del bordo e riporta l'interruzione a
;               RASTER_LINE. I registri, salvati dal Kernal prima del gestore e
;               ripristinati all'uscita, restano invariati.
;
; Input:
;   - _COUNTER (1 byte, ZP) : Righe ancora da disegnare
;
; Output:
;   - .PC (2 byte, CPU)     : Uscita con salto a IRQMIN
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  EXTCOL, RASTER, _COUNTER, VICIRQ
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq_Rasterbar

  IRQ_RASTERBAR:
    inc EXTCOL                  ; Cambia il colore del bordo.
    inc RASTER                  ; Sposta la IRQ alla linea successiva.
    dec _COUNTER                ; Decrementa il contatore di riga.
    bne .No_Last_Row            ; IF: il contatore di riga è a zero (ultima riga)

    lda #(ROWS-1)               ; Reinizializza il contatore di riga.
    sta _COUNTER

    lda #VIC_LIGHT_BLUE         ; Ripristina il colore del bordo.
    sta EXTCOL

    lda #RASTER_LINE            ; Ripristina la linea della prima IRQ.
    sta RASTER

  .No_Last_Row:
    lsr VICIRQ                  ; Permette le IRQ successive.

  .Exit_IRQ_RASTERBAR:
    jmp IRQMIN                  ; Ripristina i registri ed esce.

!zone
