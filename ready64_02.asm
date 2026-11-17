; ESERCIZIO DI RASTER #2: Stesso effetto di RASTER #1 ma con l'uso delle interruzioni
; Codice originale di 0scur0, riadattato secondo le mie convenzioni di stile. Il codice originale non è stato alterato, solo i commenti.
; https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_ready64_02.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

BASIC_START         = BASTXT

*= BASIC_START
+m_BASIC_Preamble 10,START,"ESERCIZIO DI RASTER #2"

RASTER_LINE       = 158         ; Interruzione alla linea video 158

START:
  sei                           ; Disattiva le interruzioni

  lda #<.IRQ                    ; Setta il nuovo gestore delle interruzioni
  sta CINV
  lda #>.IRQ
  sta CINV+1

  lda #RASTER_LINE              ; Interruzione alla linea 158
  sta RASTER

  lda SCROLY                    ; Azzera il bit #9 altrimenti l'interruzione verrebbe generata alla linea 256+158 (cioè mai: il valore massimo è 311=256+55, PAL)
  and #%01111111
  sta SCROLY

  lda #%00000001                ; Setta il rasterbeam come unica possibile sorgente di interruzioni generate dal VIC
  sta IRQMSK

  cli                           ; Riattiva le interruzioni

  rts

.IRQ:
  lda VICIRQ                    ; Quando il bit #0 è settato, la causa dell'interruzione è perché il rasterbeam ha raggiunto RASTER_LINE
  and #%00000001
  beq .Normal                   ; altrimenti le uniche altre possibili cause dell'interruzione sono i chip CIA 1/2

                                ; Arrivati qui il bit #0 vale 1 e fintanto che il registro VICIRQ non viene modificato nessun'altra interruzione verrà generata

  dec EXTCOL                    ; (*) CODICE AUTOMODIFICANTE: l'opcode alternerà tra "dec" e "inc"

.Alt:
  lda #$00                      ; (**) CODICE AUTOMODIFICANTE: l'argomento di "lda" alternerà tra 0 e RASTER
  sta RASTER

  lda .Alt-3                    ; Alterna il colore del bordo: vedi (*)
  eor #%00100000
  sta .Alt-3

  lda .Alt+1                    ; Alterna la linea di generazione dell'IRQ: vedi (**)
  eor #RASTER_LINE
  sta .Alt+1

  inc VICIRQ                    ; Modifica VICIRQ in modo da permette la generazione di nuove interruzioni

  jmp IRQMIN                    ; e termina il gestore di interruzioni ripristinando i registri dallo stack

.Normal:
  jmp IRQHND                    ; L'interruzione non è stata causata dal VIC: prosegui col gestore di interruzioni di sistema