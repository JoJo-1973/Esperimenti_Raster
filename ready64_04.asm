; ESERCIZIO DI RASTER #4: Genera un interruzione in più linee di raster consecutive: soluzione col doppio interrupt
; Codice originale di 0scur0, riadattato secondo le mie convenzioni di stile. Il codice originale non è stato alterato, solo i commenti.
; https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_ready64_04.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

BASIC_START         = BASTXT

*= BASIC_START
+m_BASIC_Preamble 10,START,"ESERCIZIO DI RASTER #4"

DUMMY             = UNUSE2
SCAN              = $E5CD       ; Routine senza nome del Kernal che scansiona la tastiera in attesa della pressione di un tasto

RASTER_LINE       = 16          ; Linea di inizio della rasterbar
ROWS              = 16          ; Altezza della rasterbar

START:
  lda #%00000001                ; Disattiva il timer A (la scansione dovrà essere gestita dal nostro gestore di interruzioni)
  sta CIAICR

  lda #<.IRQ_1                  ; Setta il primo gestore di interruzioni
  sta CINV
  lda #>.IRQ_1
  sta CINV+1

  lda #(RASTER_LINE-3)          ; La prima IRQ viene generata alla linea 13
  sta RASTER
  lda #%01111111
  and SCROLY
  sta SCROLY

  lda #%00000001                ; Setta il rasterbeam come unica possibile sorgente di interruzioni
  sta IRQMSK

  rts

;                               CICLI DI CLOCK
;                             TRASCORSI DALL'IRQ
;                            --------------------

.IRQ_1:                         ;
  lda #<.IRQ_2                  ; 38-44 (+2) Linea 13 - Queste temporizzazioni funzionano solo sulla versione PAL del chip VIC-II
  sta CINV                      ; 40-46 (+4) Linea 13
  lda #>.IRQ_2                  ; 44-50 (+2) Linea 13
  sta CINV+1                    ; 46-52 (+4) Linea 13
  lda #(RASTER_LINE-1)          ; 50-56 (+2) Linea 13
  sta RASTER                    ; 52-58 (+4) Linea 13
  inc VICIRQ                    ; 56-62 (+6) Linea 13 - Il rasterbeam potrebbe gia' essere sulla linea video 14 (per questo e' settato l'IRQ alla linea 15)

  cli                           ;    62-05 (+2) Linea 13/14 - Riattiva le interruzioni

  inc DUMMY                     ;    7-13    Linea 14
  dec DUMMY                     ;    13-19   Linea 14
  inc DUMMY                     ;    19-25   Linea 14
  dec DUMMY                     ;    25-31   Linea 14
  inc DUMMY                     ;    31-37   Linea 14
  dec DUMMY                     ;    37-43   Linea 14
  inc DUMMY                     ;    43-49   Linea 14
  dec DUMMY                     ;    49-55   Linea 14
  inc DUMMY                     ;    55-61   Linea 14
  nop                           ;    57-63   Linea 14
  nop                           ;    Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;    Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;    Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;    Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;   "nop" di margine

  jmp IRQHND                    ;  Permette al C64 le operazioni di routine
  jmp SCAN

.IRQ_2:
  ldy #ROWS                     ; 38-39 (+2) Linea 15 - Quando si arriva qui si sa per certo che sono passati 38 oppure 39 cicli dall'inizio della linea video 15
  inc DUMMY                     ; 46-47      Linea 15
  dec DUMMY                     ; 52-53      Linea 15
  lda DUMMY                     ; 56-57      Linea 15

.Fill:
  inc EXTCOL                    ; 62-63  +6  Linea 15 -  Aggiorna il bordo ogni 63 cicli di clock: la durata esatta di una linea di raster.
  dey                           ; 1-2    +2  Linea 16
  beq .Ret                      ; 3-4*   +2* Linea 16
  inc DUMMY                     ; 9-10   +6  Linea 16
  dec DUMMY                     ; 15-16  +6  Linea 16
  inc DUMMY                     ; 21-22  +6  Linea 16
  dec DUMMY                     ; 27-28  +6  Linea 16
  inc DUMMY                     ; 33-34  +6  Linea 16
  dec DUMMY                     ; 39-40  +6  Linea 16
  inc DUMMY                     ; 45-46  +6  Linea 16
  dec DUMMY                     ; 51-52  +6  Linea 16
  nop                           ; 53-54  +2  Linea 16
  jmp .Fill                     ; 56-57  +3  Linea 16 -  Si ritorna a .Fill allo stesso numero di cicli in cui ci si entrati per la prima volta

.Ret:
  lda #<.IRQ_1                  ; Ripristina il primo gestore delle interruzioni
  sta CINV
  lda #>.IRQ_1
  sta CINV+1

  lda #(RASTER_LINE-3)          ; Ripristina la linea video di attivazione del primo gestore delle interruzioni
  sta RASTER

  inc VICIRQ                    ; Permette le interruzioni successive
  jmp IRQMIN                    ; e termina il gestore di interruzioni ripristinando i registri dallo stack

; NOTE

; * 3 cicli invece che 2 quando avviene il salto (irrilevante)