; ESERCIZIO DI RASTER #1: Un esempio basico di effetto raster senza l'uso delle interruzioni
; Codice originale di 0scur0, riadattato secondo le mie convenzioni di stile. Il codice originale non è stato alterato, solo i commenti.
; https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_ready64_01.asm"

!source <c64/symbols.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

BASIC_START=BASTXT

*=BASIC_START
+m_BASIC_Preamble 10,START,"ESERCIZIO DI RASTER #1"

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