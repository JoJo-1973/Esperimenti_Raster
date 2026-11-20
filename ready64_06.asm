; ==============================================================================
; FILE:           ready64_06.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esercizio di raster #6: genera un'interruzione su più linee di
;                 raster consecutive: soluzione con uno sprite. Lo sprite 0, la
;                 cui ultima linea di scansione coincide con la linea dell'IRQ,
;                 fa arrestare la CPU per il DMA ai cicli 55-59: la CPU riparte
;                 al ciclo 60 e le temporizzazioni successive sono note. Il
;                 codice di avvio definisce lo sprite, installa il gestore IRQ e
;                 ritorna al BASIC. Le temporizzazioni valgono solo per il
;                 VIC-II PAL. Codice originale di 0scur0, riadattato secondo le
;                 convenzioni di stile: del codice originale sono stati alterati
;                 solo i commenti e i nomi delle etichette e dei simboli. Fonte
;                 dell'articolo originale su Ready 64:
;                 https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster
; CONTENUTO:      DEFINE_SPRITE   Definisce lo sprite 0
;                 IRQ_1           Gestore IRQ: disegna la rasterbar
; DIPENDENZE:     "config_ready64_06.asm"
;                 <c64/symbols.asm>
;                 <chip/cia.asm>
;                 <chip/vic_ii.asm>
;                 <system/standard.asm>
; REQUISITI ZP:   Nessuno
; ==============================================================================

; ------------------------------------------------------------------------------
; Uscita e processore
; ------------------------------------------------------------------------------

!to "ready64 06.prg", cbm
!cpu 6510
!sl "ready64_06.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_ready64_06.asm", once

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
; ($0826-$084A) Codice principale
; ($084B-$085D) Definizione dello sprite
; ($085E-$0890) Gestore IRQ della rasterbar

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

_DUMMY              = UNUSE2    ; Cella per le istruzioni che consumano cicli
RASTER_LINE         = 21        ; Linea di inizio della rasterbar
ROWS                = 15        ; Altezza della rasterbar

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESERCIZIO DI RASTER #6"

; [MAPPA: Codice principale]
START:
  lda #%00000001                ; Disattiva il timer A del CIA 1.
  sta CIAICR

  jsr DEFINE_SPRITE             ; Definisce lo sprite 0.

  lda #<IRQ_1                   ; Imposta il primo gestore IRQ.
  sta CINV
  lda #>IRQ_1
  sta CINV+1

  lda #(RASTER_LINE-1)          ; La prima IRQ è alla linea 20.
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

; [MAPPA: Definizione dello sprite]
; ==============================================================================
; SUBROUTINE: DEFINE_SPRITE
; ------------------------------------------------------------------------------
; Descrizione:  Definisce lo sprite 0: lo posiziona alle coordinate (0; 0) e lo
;               abilita. Con la coordinata verticale 0 l'ultima linea di
;               scansione dello sprite è la linea 20 (RASTER_LINE-1), cioè la
;               linea in cui viene generata la prima IRQ.
;
; Input:
;   - Nessuno
;
; Output:
;   - Nessuno
;
; Variazione Stack (.S):
;   - Stabile
;
; Registri Modificati:  .A, .X, .Y, .P (Negative, Zero), SP0X, SP0Y, MSIGX,
;                       SPENA
; Dipendenze Esterne:   <chip/vic_ii.asm>
; ==============================================================================
!zone Define_Sprite

  DEFINE_SPRITE:
    lda #%00000001
    ldx #0
    ldy #0
    stx SP0X
    sty SP0Y
    sty MSIGX
    sta SPENA

  .Exit_DEFINE_SPRITE:
    rts

!zone

; [MAPPA: Gestore IRQ della rasterbar]
; ==============================================================================
; SUBROUTINE: IRQ_1
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ della rasterbar: viene eseguito alla linea 20
;               (RASTER_LINE-1), a 38-39 cicli dall'inizio della linea (valori
;               misurati in VICE x64sc con il BASIC fermo al prompt: il ritardo
;               dipende dall'istruzione interrotta). Il DMA dello sprite 0 ferma
;               la CPU dal ciclo 55 al 59 e la fa ripartire al 60. Se l'IRQ
;               parte a 39 (caso normale), stx parte al ciclo 60. Se parte a 38
;               (raro), stx parte al ciclo 54, viene fermata dal DMA e scrive un
;               ciclo prima: tutta la rasterbar anticipa di un ciclo. Disegna la
;               rasterbar su ROWS linee: a ogni linea imposta il colore del
;               bordo con .X, consuma i 63 cicli della linea con istruzioni
;               sulla cella _DUMMY e incrementa .X. Alla fine permette le
;               interruzioni successive e passa il controllo al gestore di
;               sistema IRQHND. Il salto bne dura 3 cicli invece di 2 quando è
;               preso. I cicli valgono solo per il VIC-II PAL.
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
; Registri Modificati:  EXTCOL, VICIRQ, _DUMMY
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq_1

  IRQ_1:
    ; Linea 20. I cicli valgono solo per il VIC-II PAL.
    ldx #$FF                    ; 38-39 (+2)   FOR (Inizializzazione)
    lda _DUMMY                  ; 40-41 (+4)   Linea 20.
    dec _DUMMY                  ; 44-45 (+6)   Linea 20.
    lda _DUMMY                  ; 50-51 (+4)   Linea 20. Dopo questa istruzione il DMA dello sprite 0 ferma
                                ;              la CPU (cicli 55-59).

  .Loop_Draw_Line:
    ; Con l'IRQ a 39 la CPU riparte dal DMA al ciclo 60 con questa
    ; istruzione; con l'IRQ a 38 la inizia al ciclo 54.
    stx EXTCOL                  ; 60  (+4)     FOR (Corpo)
    dec _DUMMY                  ; 01  (+6)     Linea 21. Ora siamo all'inizio della linea 21.
    inc _DUMMY                  ; 07  (+6)     Linea 21.
    dec _DUMMY                  ; 13  (+6)     Linea 21.
    inc _DUMMY                  ; 19  (+6)     Linea 21.
    dec _DUMMY                  ; 25  (+6)     Linea 21.
    inc _DUMMY                  ; 31  (+6)     Linea 21.
    dec _DUMMY                  ; 37  (+6)     Linea 21.
    inc _DUMMY                  ; 43  (+6)     Linea 21.
    nop                         ; 49  (+2)     Linea 21.
    nop                         ; 51  (+2)     Linea 21.

  .Next_Draw_Line:
    inx                         ; 53  (+2)     NEXT: incrementa il colore e il contatore
    cpx #ROWS                   ; 55  (+2)     Linea 21.
    ; Si ritorna a .Loop_Draw_Line allo stesso ciclo di clock
    ; della prima volta.
    bne .Loop_Draw_Line         ; 57  (+3/2)   NEXT: ripete finché .X è diverso da ROWS

  .Exit_IRQ_1:
    inc VICIRQ                  ; Permette le IRQ successive.
    jmp IRQHND                  ; Permette al C64 le operazioni di routine.

!zone
