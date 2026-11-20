; ==============================================================================
; FILE:           ready64_05.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esercizio di raster #5: genera un'interruzione su più linee di
;                 raster consecutive: soluzione col doppio interrupt e le
;                 badline (la seconda IRQ è stabilizzata dai nop della prima; a
;                 ogni linea si alterna il valore di SCROLY). Il codice di avvio
;                 installa il primo gestore IRQ e ritorna al BASIC. Le
;                 temporizzazioni valgono solo per il VIC-II PAL. Codice
;                 originale di 0scur0, riadattato secondo le convenzioni di
;                 stile: del codice originale sono stati alterati solo i
;                 commenti e i nomi delle etichette e dei simboli. Fonte
;                 dell'articolo originale su Ready 64:
;                 https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster
; CONTENUTO:      IRQ_1   Primo gestore IRQ: prepara la doppia interruzione
;                 IRQ_2   Secondo gestore IRQ: disegna la rasterbar
; DIPENDENZE:     "config_ready64_05.asm"
;                 <c64/symbols.asm>
;                 <chip/cia.asm>
;                 <chip/vic_ii.asm>
;                 <system/standard.asm>
; REQUISITI ZP:   Nessuno
; ==============================================================================

; ------------------------------------------------------------------------------
; Uscita e processore
; ------------------------------------------------------------------------------

!to "ready64 05.prg", cbm
!cpu 6510
!sl "ready64_05.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_ready64_05.asm", once

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
; ($0826-$0847) Codice principale
; ($0848-$0881) Primo gestore IRQ
; ($0882-$08CC) Secondo gestore IRQ

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

_DUMMY              = UNUSE2    ; Cella per le istruzioni che consumano cicli
SCAN                = $E5CD     ; Routine del Kernal che scansiona la tastiera
RASTER_LINE         = 155       ; Linea di inizio della rasterbar
ROWS                = 16        ; Altezza della rasterbar

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESERCIZIO DI RASTER #5"

; [MAPPA: Codice principale]
START:
  lda #%00000001                ; Disattiva il timer A del CIA 1.
  sta CIAICR

  lda #<IRQ_1                   ; Imposta il primo gestore IRQ.
  sta CINV
  lda #>IRQ_1
  sta CINV+1

  lda #(RASTER_LINE-3)          ; La prima IRQ è alla linea 152.
  sta RASTER
  lda #%01111111
  and SCROLY
  sta SCROLY

  lda #%00000001                ; Il raster è una possibile sorgente di IRQ del VIC.
  sta IRQMSK

.Exit_START:
  rts

; ------------------------------------------------------------------------------
; Subroutine del codice
; ------------------------------------------------------------------------------

; [MAPPA: Primo gestore IRQ]
; ==============================================================================
; SUBROUTINE: IRQ_1
; ------------------------------------------------------------------------------
; Descrizione:  Primo gestore IRQ della rasterbar: viene eseguito alla linea 152
;               (RASTER_LINE-3). Imposta IRQ_2 come gestore e la linea 154
;               (RASTER_LINE-1) come linea della prossima interruzione,
;               riabilita le interruzioni con cli e consuma cicli con istruzioni
;               sulla cella _DUMMY fino ai nop, che la seconda IRQ interrompe:
;               il passaggio a IRQ_2 avviene dopo 2+7+29=38 cicli oppure dopo
;               1+2+7+29=39 cicli. Quando IRQ_2 ritorna, prosegue con il gestore
;               di sistema IRQHND. I cicli valgono solo per il VIC-II PAL.
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Uscita con salto a IRQHND
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  CINV, RASTER, VICIRQ, _DUMMY
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq_1

  IRQ_1:
    lda #<IRQ_2                 ; 38-44 (+2)   Linea 152. Valido solo per il VIC-II PAL.
    sta CINV                    ; 40-46 (+4)   Linea 152.
    lda #>IRQ_2                 ; 44-50 (+2)   Linea 152.
    sta CINV+1                  ; 46-52 (+4)   Linea 152.
    lda #(RASTER_LINE-1)        ; 50-56 (+2)   Linea 152.
    sta RASTER                  ; 52-58 (+4)   Linea 152.
    inc VICIRQ                  ; 56-62 (+6)   Linea 152.

    cli                         ; 62-05 (+2)   Linee 152/153. Riattiva le interruzioni.
                                ;              Il raster potrebbe già essere alla linea 153:
                                ;              per questo la prossima IRQ è alla linea 154.

    inc _DUMMY                  ; 01-07 (+6)   Linea 153.
    dec _DUMMY                  ; 07-13 (+6)   Linea 153.
    inc _DUMMY                  ; 13-19 (+6)   Linea 153.
    dec _DUMMY                  ; 19-25 (+6)   Linea 153.
    inc _DUMMY                  ; 25-31 (+6)   Linea 153.
    dec _DUMMY                  ; 31-37 (+6)   Linea 153.
    inc _DUMMY                  ; 37-43 (+6)   Linea 153.
    dec _DUMMY                  ; 43-49 (+6)   Linea 153.
    inc _DUMMY                  ; 49-55 (+6)   Linea 153.
    nop                         ; 55-61 (+2)   Linea 153.
    nop                         ; 57-63 (+2)   Possibile IRQ: passaggio a IRQ_2 dopo 38 o 39 cicli.
    nop                         ; 59-02 (+2)   Possibile IRQ: passaggio a IRQ_2 dopo 38 o 39 cicli.
    nop                         ; 61-04 (+2)   Possibile IRQ: passaggio a IRQ_2 dopo 38 o 39 cicli.
    nop                         ; 63-06 (+2)   Possibile IRQ: passaggio a IRQ_2 dopo 38 o 39 cicli.
    nop                         ; 02-08 (+2)   Nop di margine.

  .Exit_IRQ_1:
    jmp IRQHND                  ; Permette al C64 le operazioni di routine.
    jmp SCAN

!zone

; [MAPPA: Secondo gestore IRQ]
; ==============================================================================
; SUBROUTINE: IRQ_2
; ------------------------------------------------------------------------------
; Descrizione:  Secondo gestore IRQ della rasterbar: viene eseguito alla linea
;               154 (RASTER_LINE-1), con un ritardo certo di 38 o 39 cicli
;               dall'inizio della linea. Disegna la rasterbar su ROWS linee: a
;               ogni linea incrementa EXTCOL, alterna il valore del registro di
;               scroll SCROLY e consuma con istruzioni sulla cella _DUMMY i
;               63 cicli della linea, così il cambio di colore avviene sempre
;               allo stesso ciclo. L'alternanza di SCROLY modifica l'opcode
;               dell'istruzione che lo scrive, da inc a dec e viceversa.
;               All'ultima linea ripristina SCROLY, IRQ_1 come gestore e
;               RASTER_LINE-3 come linea di interruzione, poi esce con IRQMIN.
;               Il salto beq dura 3 cicli invece di 2 quando è preso
;               (irrilevante). I cicli valgono solo per il VIC-II PAL.
;
;               ATTENZIONE: codice automodificante indicato con (!!!)
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Uscita con salto a IRQMIN
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  EXTCOL, SCROLY, CINV, RASTER, VICIRQ, _DUMMY
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq_2

  IRQ_2:
    ldy #ROWS                   ; 38-39 (+2)   Linea 154. Qui sono passati di certo 38 o 39 cicli
                                ;              dall'inizio della linea video 154.
    inc _DUMMY                  ; 40-41 (+6)   Linea 154.
    dec _DUMMY                  ; 46-47 (+6)   Linea 154.
    lda _DUMMY                  ; 52-53 (+4)   Linea 154.

  .Loop_Draw_Line:
    ; Aggiorna il bordo ogni 63 cicli di clock: la durata esatta
    ; di una linea di raster.
    inc EXTCOL                  ; 56-57 (+6)   FOREVER
    dey                         ; 62-63 (+2)   Linea 154.
    beq .Exit_IRQ_2             ; 01-02 (+3/2) Linea 155.

  .Scroll_Opcode:
    inc SCROLY                  ; 03-04 (+6)   (!!!#1) L'opcode alterna inc e dec.
    lda #%00100000              ; 09-10 (+2)   Linea 155.
    eor .Scroll_Opcode          ; 11-12 (+4)   Linea 155.
    sta .Scroll_Opcode          ; 15-16 (+4)   (!!!#1) Alterna il valore del registro di scroll.
    inc _DUMMY                  ; 19-20 (+6)   Linea 155.
    dec _DUMMY                  ; 25-26 (+6)   Linea 155.
    inc _DUMMY                  ; 31-32 (+6)   Linea 155.
    dec _DUMMY                  ; 37-38 (+6)   Linea 155.
    inc _DUMMY                  ; 43-44 (+6)   Linea 155.
    lda _DUMMY                  ; 49-50 (+4)   Linea 155.
    ; Si ritorna a .Loop_Draw_Line allo stesso ciclo di clock
    ; della prima volta.
    jmp .Loop_Draw_Line         ; 53-54 (+3)   FOREVER: ripete per ogni linea della rasterbar

  .Exit_IRQ_2:
    lda #%00011011              ; Ripristina lo scroll verticale fuori dalle rasterbar.
    sta SCROLY

    lda #<IRQ_1                 ; Ripristina il primo gestore IRQ.
    sta CINV
    lda #>IRQ_1
    sta CINV+1

    lda #(RASTER_LINE-3)        ; Ripristina la linea del primo gestore IRQ.
    sta RASTER

    inc VICIRQ                  ; Permette le IRQ successive.
    jmp IRQMIN                  ; Ripristina i registri ed esce.

!zone
