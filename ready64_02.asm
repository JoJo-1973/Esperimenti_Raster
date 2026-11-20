; ==============================================================================
; FILE:           ready64_02.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esercizio di raster #2: stesso effetto di ready64_01.asm, ma
;                 con l'uso delle interruzioni di raster. Il codice di avvio
;                 installa il gestore IRQ e ritorna al BASIC; il gestore cambia
;                 il colore del bordo dalla linea video fissa alla linea 0.
;                 Codice originale di 0scur0, riadattato secondo le convenzioni
;                 di stile: del codice originale sono stati alterati solo i
;                 commenti e i nomi delle etichette. Articolo originale:
;                 https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster
; CONTENUTO:      IRQ_BORDER  Gestore IRQ: alterna il colore del bordo
; DIPENDENZE:     "config_ready64_02.asm"
;                 <c64/symbols.asm>
;                 <chip/vic_ii.asm>
;                 <system/standard.asm>
; REQUISITI ZP:   Nessuno
; ==============================================================================

; ------------------------------------------------------------------------------
; Uscita e processore
; ------------------------------------------------------------------------------

!to "ready64 02.prg", cbm
!cpu 6510
!sl "ready64_02.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_ready64_02.asm", once

; ------------------------------------------------------------------------------
; Simboli
; ------------------------------------------------------------------------------

!source <c64/symbols.asm>, once
!source <chip/vic_ii.asm>, once

; ------------------------------------------------------------------------------
; Mappa di memoria
; ------------------------------------------------------------------------------

BASIC_START         = BASTXT

; ($0801-$0825) Preambolo BASIC
; ($0826-$0844) Codice principale
; ($0845-$086C) Gestore IRQ del bordo

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

RASTER_LINE         = 158       ; Linea video in cui cambia il bordo

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESERCIZIO DI RASTER #2"

; [MAPPA: Codice principale]
START:
  sei                           ; Disattiva le interruzioni.

  ; Imposta il nuovo gestore delle interruzioni.
  lda #<IRQ_BORDER
  sta CINV
  lda #>IRQ_BORDER
  sta CINV+1

  ; Imposta la linea video della prima interruzione.
  lda #RASTER_LINE
  sta RASTER

  ; Azzera il bit #7 di SCROLY (bit alto della linea): con 1
  ; l'interruzione sarebbe alla linea 256+158, cioè mai, perché
  ; il valore massimo è 311 (PAL).
  lda SCROLY
  and #%01111111
  sta SCROLY

  ; Il raster è l'unica sorgente di interruzioni del VIC.
  lda #%00000001
  sta IRQMSK

  cli                           ; Riattiva le interruzioni.

.Exit_START:
  rts

; ------------------------------------------------------------------------------
; Subroutine del codice
; ------------------------------------------------------------------------------

; [MAPPA: Gestore IRQ del bordo]
; ==============================================================================
; SUBROUTINE: IRQ_BORDER
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ del raster: alterna il colore del bordo tra la linea
;               RASTER_LINE e la linea 0. Se l'interruzione è del VIC, alla
;               linea RASTER_LINE decrementa EXTCOL e sposta la prossima
;               interruzione alla linea 0; alla linea 0 lo incrementa e la
;               riporta a RASTER_LINE. Per alternare le due azioni modifica il
;               proprio codice: l'opcode di .Border_Opcode passa da dec a inc e
;               viceversa, e l'operando di .Line_Operand da 0 a RASTER_LINE e
;               viceversa. Se l'interruzione non è del VIC, passa il controllo
;               al gestore di sistema (IRQHND). Il Kernal salva i registri prima
;               del gestore e li ripristina all'uscita: restano invariati per il
;               codice interrotto.
;
;               ATTENZIONE: codice automodificante indicato con (!!!)
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Uscita con salto a IRQMIN o a IRQHND
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  EXTCOL, RASTER, VICIRQ
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq_Border

  IRQ_BORDER:
    ; Il bit #0 di VICIRQ vale 1 se il raster ha raggiunto la
    ; linea impostata; altrimenti l'IRQ viene dai chip CIA 1/2.
    lda VICIRQ
    and #%00000001
    beq .Exit_IRQ_BORDER_Not_Raster

  .Border_Opcode:
    ; Finché VICIRQ non cambia, il VIC non genera altre IRQ.
    dec EXTCOL                  ; (!!!#1) L'opcode alterna dec e inc.

  .Line_Operand:
    lda #$00                    ; (!!!#2) L'operando alterna 0 e RASTER_LINE.
    sta RASTER

    ; Alterna l'opcode del bordo: dec e inc.
    lda .Border_Opcode
    eor #%00100000
    sta .Border_Opcode          ; (!!!#1)

    ; Alterna la linea della prossima interruzione.
    lda .Line_Operand+1
    eor #RASTER_LINE
    sta .Line_Operand+1         ; (!!!#2)

    inc VICIRQ                  ; Permette nuove interruzioni.

  .Exit_IRQ_BORDER:
    jmp IRQMIN                  ; Ripristina i registri ed esce.

  .Exit_IRQ_BORDER_Not_Raster:
    jmp IRQHND                  ; Passa al gestore di sistema.

!zone
