; RASTER_LINE #6: Genera un interruzione in più linee di raster consecutive: soluzione con sprite
; https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

+BASIC_Preamble 10,START,"ESERCIZI DI RASTER #6"

DUMMY             = UNUSE2
SCAN              = $E5CD
RASTER_LINE       = 21          ; Linea di inizio della rasterbar
ROWS              = 15          ; Altezza della rasterbar

START:
  lda #%00000001                ; Disattiva il timer A (la scansione dovrà essere gestita dal nostro gestore di interruzioni)
  sta CIAICR

  jsr .DefSprt                  ; Definisce lo sprite 0

  lda #<.IRQ_1                  ; Setta il primo gestore di interruzioni
  sta CINV
  lda #>.IRQ_1
  sta CINV+1

  lda #(RASTER_LINE-1)          ; La prima IRQ viene generata alla linea 20
  sta RASTER
  lda #%01111111
  and SCROLY
  sta SCROLY

  lda #%00000001                ; Setta il rasterbeam come possibile sorgente di interruzioni
  sta IRQMSK

  rts

.DefSprt:
  lda #$01
  ldx #$00
  ldy #$00                      ; Ultima linea di scansione dello sprite = linea di generazione dell'IRQ
  stx SP0X
  sty SP0Y
  sty MSIGX
  sta SPENA

  rts

;                               CICLI DI CLOCK
;                             TRASCORSI DALL'IRQ
;                            --------------------

.IRQ_1:                         ; 38-41
  ldx #$FF                      ; 40-43
  lda DUMMY                     ; 44-47
  dec DUMMY                     ; 50-53
  lda DUMMY                     ; 54-57 - Il microprocessore si arresta dopo questa istruzione ed il VIC si "ruba" 3 cicli

.Fill:                          ; quando la CPU inizia ad eseguire questa istruzione siamo al ciclo 60
  stx EXTCOL                    ; 63

;                                 Ora siamo esattamente all'inizio della linea 21
  dec DUMMY                     ; +6
  inc DUMMY                     ; +6
  dec DUMMY                     ; +6
  inc DUMMY                     ; +6
  dec DUMMY                     ; +6
  inc DUMMY                     ; +6
  dec DUMMY                     ; +6
  inc DUMMY                     ; +6
  nop                           ; +2
  nop                           ; +2
  inx                           ; +2
  cpx #ROWS                     ; +2
  bne .Fill                     ; +3

  inc VICIRQ                    ; Permette le interruzioni successive
  jmp IRQHND                    ; e permette al C64 le operazioni di routine
