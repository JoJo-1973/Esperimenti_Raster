; ==============================================================================
; FILE:           ready64_01.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esercizio di raster #1: un esempio basico di effetto raster
;                 senza l'uso delle interruzioni. Il colore del bordo cambia per
;                 la durata di un quadro, da una linea video fissa alla linea 0.
;                 Codice originale di 0scur0, riadattato secondo le convenzioni
;                 di stile: del codice originale sono stati alterati solo i
;                 commenti. Articolo originale:
;                 https://ready64.org/articoli/leggi/idart/112/lo-schermo-del-c64-e-il-raster
; DIPENDENZE:     "config_ready64_01.asm"
;                 <c64/symbols.asm>
;                 <chip/vic_ii.asm>
;                 <system/standard.asm>
; ==============================================================================

; ------------------------------------------------------------------------------
; Uscita e processore
; ------------------------------------------------------------------------------

!to "ready64 01.prg", cbm
!cpu 6510
!sl "ready64_01.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_ready64_01.asm", once

; ------------------------------------------------------------------------------
; Simboli
; ------------------------------------------------------------------------------

!source <c64/symbols.asm>, once
!source <chip/vic_ii.asm>, once

; ------------------------------------------------------------------------------
; Mappa di memoria
; ------------------------------------------------------------------------------

BASIC_START         = BASTXT

; ($0801-$0825) Preambolo BASIC
; ($0826-$083F) Codice principale

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

RASTER_LINE         = 158       ; Linea video in cui cambia il bordo

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESERCIZIO DI RASTER #1"

; [MAPPA: Codice principale]
START:
  lda #RASTER_LINE

.Loop_Wait_Line:
  ; Consuma cicli finché non si arriva alla linea 158.
  cmp RASTER                    ; REPEAT
  bne .Loop_Wait_Line           ; REPEAT UNTIL: la linea è 158

  dec EXTCOL                    ; Decrementa il colore del bordo.

.Loop_Wait_Line_0:
  ; Consuma cicli finché il byte basso di RASTER non è 0.
  lda RASTER                    ; REPEAT
  bne .Loop_Wait_Line_0         ; REPEAT UNTIL: il byte basso è 0

  ; Con il bit #7 di SCROLY a 1 la linea è 256, non 0.
  lda SCROLY
  bmi .Loop_Wait_Line_0         ; REPEAT UNTIL: il bit #7 vale 0

  inc EXTCOL                    ; Incrementa il colore del bordo.

  jmp START                     ; Ricomincia.
