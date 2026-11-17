; RASTER #1: Un esempio basico di effetto raster senza l'uso delle interruzioni
; https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

+BASIC_Preamble 10,START,"ESERCIZI DI RASTER #1"

RASTER_LINE       = 158         ; Interruzione alla linea video 158

START:
  lda #RASTER_LINE

.Loop:
  cmp RASTER                    ; Consuma cicli finché non si arriva alla linea 158
  bne .Loop

  dec EXTCOL                    ; Decrementa il colore del bordo

.Loop2:
  lda RASTER                    ; Consuma cicli finche il LSB del registro raster è 0
  bne .Loop2

  lda SCROLY                    ; Ma se il msb è 1 vuol dire che non siamo alla linea 0 ma alla linea 256
  bmi .Loop2

  inc EXTCOL                    ; Incrementa il colore del bordo

  jmp START                     ; Ricomincia