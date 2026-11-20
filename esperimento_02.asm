; ==============================================================================
; FILE:           esperimento_02.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esperimento di raster #2: colorazione parziale di una linea di
;                 raster ottenuta con un'interruzione stabilizzata. Soluzione
;                 implementata con le macro di raster_tools.asm.
; CONTENUTO:      MAIN  Imposta la palette e avvia l'interruzione di raster
;                 IRQ1  Gestore IRQ: Colorazione linea
; DIPENDENZE:     "config_esperimento_02.asm"
;                 <c64/symbols.asm>
;                 <chip/cia.asm>
;                 <chip/vic_ii.asm>
;                 <chip/6510_tools.asm>
;                 <chip/raster_tools.asm>
;                 <system/standard.asm>
;                 <chip/vic_ii_tools.asm>
; REQUISITI ZP:   __VIC_MODEL
; ==============================================================================

; ------------------------------------------------------------------------------
; Uscita e processore
; ------------------------------------------------------------------------------

!to "esperimento 02.prg", cbm
!cpu 6510
!sl "esperimento_02.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_esperimento_02.asm", once

; ------------------------------------------------------------------------------
; Simboli
; ------------------------------------------------------------------------------

!source <c64/symbols.asm>, once
!source <chip/cia.asm>, once
!source <chip/vic_ii.asm>, once

; ------------------------------------------------------------------------------
; Mappa di memoria
; ------------------------------------------------------------------------------

BASIC_START         = BASTXT

; ($0801-$0827) Preambolo BASIC
; ($0828-$082A) Avvio
; ($082B-$0843) Moduli di libreria
; ($0844-$084B) Variabili globali
; ($084C-$08FF) Codice principale
; ($0900-$097B) Gestore IRQ: Colorazione linea

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <chip/6510_tools.asm>, once
!source <chip/raster_tools.asm>, once
!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

LINE1               = 103

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #2"

; [MAPPA: Avvio]
START:
  jmp MAIN

; ------------------------------------------------------------------------------
; Moduli di libreria
; ------------------------------------------------------------------------------

; [MAPPA: Moduli di libreria]
!source <chip/vic_ii_tools.asm>, once

; ------------------------------------------------------------------------------
; Variabili globali
; ------------------------------------------------------------------------------

; [MAPPA: Variabili globali]
PALETTE:
  !byte VIC_BLUE, VIC_BLUE, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_TRANSPARENT

; ------------------------------------------------------------------------------
; Codice principale
; ------------------------------------------------------------------------------

; [MAPPA: Codice principale]
; ==============================================================================
; SUBROUTINE: MAIN
; ------------------------------------------------------------------------------
; Descrizione:  Programma principale: imposta i colori del VIC-II con la tabella
;               PALETTE, inizializza il sistema delle interruzioni di raster e
;               avvia l'interruzione stabilizzata IRQ1, che colora in bianco
;               parte della linea di raster LINE1. Se il Kernal è abilitato
;               (__DISABLE_KERNAL = 0) ritorna al BASIC e l'interruzione
;               continua a colorare la linea. Se il Kernal è disabilitato
;               (__DISABLE_KERNAL = 1) non ritorna: incrementa di continuo la
;               prima cella dello schermo.
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Ritorno al chiamante; non ritorna se
;                         __DISABLE_KERNAL = 1
;
; Variazione Stack (.S):
;   - Stabile
;
; Registri Modificati:  .A, .X, .Y, .P (Negative, oVerflow, Interrupt, Zero,
;                       Carry), INDEX2, EXTCOL, BGCOL0, BGCOL1, BGCOL2, BGCOL3,
;                       SPMC0, SPMC1, COLOR, __VIC_MODEL, CIAICR, CI2ICR,
;                       VICIRQ, IRQMSK, RASTER, SCROLY,
;                       VICSCN (se __DISABLE_KERNAL = 1),
;                       R6510 (se __DISABLE_KERNAL = 1),
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/raster_tools.asm>
;                       <chip/vic_ii_tools.asm>
; ==============================================================================
!zone Main

  MAIN:
    lda #<PALETTE
    ldx #>PALETTE
    jsr VIC_PALETTE

    +m_Init_Raster_System                             ; Inizializza la catena delle interruzioni.
    +m_Start_Raster_IRQ "STABLE", LINE1, IRQ1

  !if (__DISABLE_KERNAL = 1) {

    .Loop_Increment_Cell:
      ; Un semplice effetto per mostrare che il computer non si
      ; blocca quando il Kernal è disabilitato.
      inc VICSCN                                      ; FOREVER
      jmp .Loop_Increment_Cell                        ; FOREVER: incrementa la prima cella dello schermo
  } else {

    .Exit_MAIN:
      rts
  }

!zone

; ------------------------------------------------------------------------------
; Subroutine del codice
; ------------------------------------------------------------------------------

  !align $00FF, 0, $00                                ; Allinea il gestore delle interruzioni alla pagina.

; [MAPPA: Gestore IRQ: Colorazione linea]
; ==============================================================================
; SUBROUTINE: IRQ1
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a LINE1: colora di bianco parte della linea di
;               raster e ripristina il blu. Grazie all'interruzione stabilizzata
;               il cambio di colore avviene a un ciclo esatto della linea.
;               Prepara l'interruzione di raster successiva, ancora a LINE1, il
;               cui gestore è IRQ1. I registri e i flag, salvati all'ingresso e
;               ripristinati all'uscita, risultano invariati per il codice
;               interrotto. Sullo stack il gestore consuma i 3 byte che
;               l'interruzione ha salvato.
;
;               Con il Kernal abilitato l'uscita passa per IRQHND, che scansiona
;               la tastiera e aggiorna i timer: le celle di lavoro del Kernal
;               che altera non hanno un contenuto garantito dopo la chiamata.
;               Con il Kernal disabilitato l'uscita è sempre veloce.
;
; Input:
;   - __VIC_MODEL (1 byte, ZP) : Modello VIC-II (vedi m_Init_Raster_System)
;
; Output:
;   - .PC (2 byte, CPU)        : Uscita con rti o salto a IRQHND
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  BGCOL0, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq1

  IRQ1:
    +m_Enter_Raster_IRQ "STABLE", LINE1               ; Colora parzialmente la linea di raster in bianco.
    nop                                               ; 03  (+2)
    nop                                               ; 05  (+2)
    nop                                               ; 07  (+2)
    nop                                               ; 09  (+2)

    lda #VIC_WHITE                                    ; 11  (+2)
    sta BGCOL0                                        ; 13  (+4)     Lo sfondo diventa bianco al 16 ciclo, cioè il ciclo
                                                      ;              corrispondente al disegno della colonna 0.
    lda #VIC_BLUE                                     ; 17  (+2)
    sta BGCOL0                                        ; 19  (+4)     Lo sfondo torna azzurro al 22 ciclo, cioè il ciclo
                                                      ;              corrispondente al disegno della colonna 6.
                                                      ; 23  ...      Pertanto la linea bianca è lunga esattamente
                                                      ;              22-16=6 caratteri (tranne un ineliminabile pixel
                                                      ;              di sfasamento).

  .Exit_IRQ1:
    +m_Next_Raster_IRQ "STABLE", LINE1, IRQ1, "SLOW"  ; L'unico gestore IRQ della catena deve occuparsi anche della
                                                      ; scansione della tastiera.

!zone
