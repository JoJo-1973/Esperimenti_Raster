; RASTER #3: Genera un interruzione in più linee di raster consecutive: primo approccio fallimentare
; https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

+BASIC_Preamble 10,START,"ESERCIZI DI RASTER #3"

RASTER_LINE       = 16          ; Interruzione alla linea video 16
ROWS              = 16          ; Altezza della rasterbar
COUNTER           = UNUSED      ; Contatore di linea

START:
  sei

  lda #(ROWS-1)                 ; Inizializza il contatore di riga
  sta COUNTER

  lda #<.IRQ                    ; Setta il nuovo gestore delle interruzioni
  sta CINV
  lda #>.IRQ
  sta CINV+1

  lda #RASTER_LINE              ; Interruzione alla linea 16
  sta RASTER
  lda SCROLY
  and #%01111111
  sta SCROLY

  lda #%00000001                ; Setta il rasterbeam come unica possibile sorgente di interruzioni
  sta IRQMSK

  lda #%01111111                ; Disabilita tutte le sorgenti di interruzioni provenienti dal CIA1
  sta CIAICR

  cli

  rts

.IRQ:
  inc EXTCOL                    ; Cambia il colore del bordo
  inc RASTER                    ; Setta la prossima linea come la successiva linea di interruzione
  dec COUNTER                   ; Decrementa il contatore di riga
  bne .Exit                     ; Ultima riga? No? Esci

  lda #(ROWS-1)                 ; Reinizializza il contatore di riga
  sta COUNTER

  lda #$FE                      ; Ripristina il colore del bordo
  sta EXTCOL

  lda #RASTER_LINE
  sta RASTER                    ; Ripristina il contatore di riga

.Exit:
  lsr VICIRQ                    ; Permette le interruzioni successive
  jmp IRQMIN                    ; e termina il gestore di interruzioni ripristinando i registri dallo stack