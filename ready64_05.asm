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
SCAN              = $E5CD
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

.IRQ_1:                         ; 38-44
  lda #<.IRQ_2                  ; 40-46
  sta CINV                      ; 44-50
  lda #>.IRQ_2                  ; 46-52
  sta CINV+1                    ; 50-56
  lda #(RASTER_LINE-1)          ; 52-58
  sta RASTER                    ; 56-62
  inc VICIRQ                    ; 62-68 - il raster potrebbe già essere sulla linea video 153 (per questo è settato l'IRQ alla linea 154)

  cli                           ; Linea 153    cicli 1-7         (riattiva la modalità IRQ)

  inc DUMMY                     ; Linea 153    cicli 7-13
  dec DUMMY                     ; Linea 153    cicli 13-19
  inc DUMMY                     ; Linea 153    cicli 19-25
  dec DUMMY                     ; Linea 153    cicli 25-31
  inc DUMMY                     ; Linea 153    cicli 31-37
  dec DUMMY                     ; Linea 153    cicli 37-43
  inc DUMMY                     ; Linea 153    cicli 43-49
  dec DUMMY                     ; Linea 153    cicli 49-55
  inc DUMMY                     ; Linea 153    cicli 55-61
  nop                           ; Linea 153    cicli 57-63
  nop                           ;  - Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;  - Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;  - Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;  - Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;  "nop" di margine

  jmp IRQHND                    ;  Permette al C64 le operazioni di routine
  jmp SCAN

.IRQ_2:                         ; Quando si arriva qui si sa per certo che sono passati 38 oppure 39 cicli dall'inizio della linea video 154
  ldy #ROWS                     ; Linea 154    cicli 40-41
  inc DUMMY                     ; Linea 154    cicli 46-47
  dec DUMMY                     ; Linea 154    cicli 52-53
  lda DUMMY                     ; Linea 154    cicli 56-57

.Fill:
  inc EXTCOL                    ; Linea 154    cicli 62-63  +6  - Aggiorna il bordo ogni 63 cicli di clock
  dey                           ; Linea 155    cicli 1-2    +2    (la durata esatta di una linea di raster)
  beq .Ret                      ; Linea 155    cicli 3-4*   +2*
  inc SCROLY                    ; Linea 155    cicli 9-10   +6  - (*) CODICE AUTOMODIFICANTE: l'opcode alternerà tra "inc" e "dec"
  lda #%00100000                ; Linea 155    cicli 11-12  +2
  eor .Fill+6                   ; Linea 155    cicli 15-16  +4
  sta .Fill+6                   ; Linea 155    cicli 19-10  +4  -  Alterna il valore del registro di scroll: vedi (*)
  inc DUMMY                     ; Linea 155    cicli 25-26  +6
  dec DUMMY                     ; Linea 155    cicli 31-32  +6
  inc DUMMY                     ; Linea 155    cicli 37-38  +6
  dec DUMMY                     ; Linea 155    cicli 43-44  +6
  inc DUMMY                     ; Linea 155    cicli 49-50  +6
  lda DUMMY                     ; Linea 155    cicli 53-54  +4
  jmp .Fill                     ; Linea 155    cicli 56-57  +3  -  Si ritorna a .Fill nelle stesse condizioni in cui ci si entrati per la prima volta

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