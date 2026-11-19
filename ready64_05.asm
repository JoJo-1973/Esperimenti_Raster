; ESERCIZIO DI RASTER #5: Genera un interruzione in più linee di raster consecutive: soluzione col doppio interrupt & badlines
; Codice originale di 0scur0, riadattato secondo le mie convenzioni di stile. Il codice originale non è stato alterato, solo i commenti.
; https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_ready64_05.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

BASIC_START         = BASTXT

*= BASIC_START
+m_BASIC_Preamble 10,START,"ESERCIZIO DI RASTER #5"

DUMMY             = UNUSE2
SCAN              = $E5CD       ; Routine senza nome del Kernal che scansiona la tastiera in attesa della pressione di un tasto
RASTER_LINE       = 155         ; Linea di inizio della rasterbar
ROWS              = 16          ; Altezza della rasterbar

START:
  lda #%00000001                ; Disattiva il timer A (la scansione dovrà essere gestita dal nostro gestore di interruzioni)
  sta CIAICR

  lda #<.IRQ_1                  ; Setta il primo gestore di interruzioni
  sta CINV
  lda #>.IRQ_1
  sta CINV+1

  lda #(RASTER_LINE-3)          ; La prima IRQ viene generata alla linea 152
  sta RASTER
  lda #%01111111
  and SCROLY
  sta SCROLY

  lda #%00000001                ; Setta il rasterbeam come possibile sorgente di interruzioni
  sta IRQMSK

  rts

;                               CICLI DI CLOCK
;                             TRASCORSI DALL'IRQ
;                            --------------------

.IRQ_1:                         ;
  lda #<.IRQ_2                  ; 38-44 (+2) Linea 152 - Queste temporizzazioni funzionano solo sulla versione PAL del chip VIC-II
  sta CINV                      ; 40-46 (+4) Linea 152
  lda #>.IRQ_2                  ; 44-50 (+2) Linea 152
  sta CINV+1                    ; 46-52 (+4) Linea 152
  lda #(RASTER_LINE-1)          ; 50-56 (+2) Linea 152
  sta RASTER                    ; 52-58 (+4) Linea 152
  inc VICIRQ                    ; 56-62 (+6) Linea 152 - Il raster potrebbe già essere sulla linea video 153 (per questo è settato l'IRQ alla linea 154)

  cli                           ; 62-05 (+2) Linea 152/153 - Riattiva le interruzioni

  inc DUMMY                     ; 07-13      Linea 153
  dec DUMMY                     ; 13-19      Linea 153
  inc DUMMY                     ; 19-25      Linea 153
  dec DUMMY                     ; 25-31      Linea 153
  inc DUMMY                     ; 31-37      Linea 153
  dec DUMMY                     ; 37-43      Linea 153
  inc DUMMY                     ; 43-49      Linea 153
  dec DUMMY                     ; 49-55      Linea 153
  inc DUMMY                     ; 55-61      Linea 153
  nop                           ; 57-63      Linea 153
  nop                           ; Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ; Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ; Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ; Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ; "nop" di margine

  jmp IRQHND                    ; Permette al C64 le operazioni di routine
  jmp SCAN

.IRQ_2:                         ;
  ldy #ROWS                     ; 38-39 (+2) Linea 154 - Quando si arriva qui si sa per certo che sono passati 38 oppure 39 cicli dall'inizio della linea video 154
  inc DUMMY                     ; 46-47      Linea 154
  dec DUMMY                     ; 52-53      Linea 154
  lda DUMMY                     ; 56-57      Linea 154

.Fill:
  inc EXTCOL                    ; 62-63  +6  Linea 154 - Aggiorna il bordo ogni 63 cicli di clock
  dey                           ; 1-2    +2  Linea 155   (la durata esatta di una linea di raster)
  beq .Ret                      ; 3-4*   +2* Linea 155
  inc SCROLY                    ; 9-10   +6  Linea 155 - (*) CODICE AUTOMODIFICANTE: l'opcode alternerà tra "inc" e "dec"
  lda #%00100000                ; 11-12  +2  Linea 155
  eor .Fill+6                   ; 15-16  +4  Linea 155
  sta .Fill+6                   ; 19-10  +4  Linea 155 - Alterna il valore del registro di scroll: vedi (*)
  inc DUMMY                     ; 25-26  +6  Linea 155
  dec DUMMY                     ; 31-32  +6  Linea 155
  inc DUMMY                     ; 37-38  +6  Linea 155
  dec DUMMY                     ; 43-44  +6  Linea 155
  inc DUMMY                     ; 49-50  +6  Linea 155
  lda DUMMY                     ; 53-54  +4  Linea 155
  jmp .Fill                     ; 56-57  +3  Linea 155 - Si ritorna a .Fill allo stesso numero di cicli in cui ci si entrati per la prima volta

.Ret:
  lda #$1B                      ; Ripristina il registro di scroll verticale fuori dalle rasterbars
  sta SCROLY

  lda #<.IRQ_1                  ; Ripristina il primo gestore delle interruzioni
  sta CINV
  lda #>.IRQ_1
  sta CINV+1

  lda #(RASTER_LINE-3)          ; Ripristina la linea video di attivazione del primo gestore delle interruzioni
  sta RASTER

  inc VICIRQ                    ; Permette le interruzioni successive
  jmp IRQMIN                    ; e termina il gestore di interruzioni ripristinando i registri dallo stack

; NOTE

; * 3 cicli quando avviene il salto (irrilevante)