; ESERCIZIO DI RASTER #6: Genera un interruzione in più linee di raster consecutive: soluzione con sprite
; Codice originale di 0scur0, riadattato secondo le mie convenzioni di stile. Il codice originale non è stato alterato, solo i commenti.
; https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_ready64_06.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

BASIC_START         = BASTXT

*= BASIC_START
+m_BASIC_Preamble 10,START,"ESERCIZIO DI RASTER #6"

DUMMY             = UNUSE2
SCAN              = $E5CD       ; Routine senza nome del Kernal che scansiona la tastiera in attesa della pressione di un tasto
RASTER_LINE       = 21          ; Linea di inizio della rasterbar
ROWS              = 15          ; Altezza della rasterbar

START:
  lda #%00000001                ; Disattiva il timer A (la scansione dovrà essere gestita dal nostro gestore di interruzioni)
  sta CIAICR

  jsr DEFINE_SPRITE      ; Definisce lo sprite 0

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

DEFINE_SPRITE
  lda #$01
  ldx #$00
  ldy #$00
  stx SP0X
  sty SP0Y ; Ultima linea di scansione dello sprite = linea di generazione dell'IRQ
  sty MSIGX
  sta SPENA

  rts

;                               CICLI DI CLOCK
;                             TRASCORSI DALL'IRQ
;                            --------------------

.IRQ_1:
  ldx #$FF                      ; 38-41 (+2) Linea 20 - Queste temporizzazioni funzionano solo sulla versione PAL del chip VIC-II
  lda DUMMY                     ; 40-43 (+4) Linea 20
  dec DUMMY                     ; 44-47 (+6) Linea 20
  lda DUMMY                     ; 50-53 (+4) Linea 20 - Il microprocessore si arresta dopo questa istruzione ed il VIC-II si "ruba" 3 cicli

.Fill:
  stx EXTCOL                    ; 60    (+4) Linea 20 - Quando la CPU inizia ad eseguire questa istruzione siamo al ciclo 60


  dec DUMMY                     ; 1  (+6)     Linea 21 - Ora siamo esattamente all'inizio della linea 21
  inc DUMMY                     ; 7  (+6)     Linea 21
  dec DUMMY                     ; 13 (+6)     Linea 21
  inc DUMMY                     ; 19 (+6)     Linea 21
  dec DUMMY                     ; 25 (+6)     Linea 21
  inc DUMMY                     ; 31 (+6)     Linea 21
  dec DUMMY                     ; 37 (+6)     Linea 21
  inc DUMMY                     ; 43 (+6)     Linea 21
  nop                           ; 49 (+2)     Linea 21
  nop                           ; 51 (+2)     Linea 21
  inx                           ; 53 (+2)     Linea 21
  cpx #ROWS                     ; 55 (+2)     Linea 21
  bne .Fill                     ; 57 (+3)     Linea 21 - Si ritorna a .Fill allo stesso numero di cicli in cui ci si entrati per la prima volta


  inc VICIRQ                    ; Permette le interruzioni successive
  jmp IRQHND                    ; e permette al C64 le operazioni di routine
