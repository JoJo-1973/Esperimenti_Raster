; ==============================================================================
; FILE:           esperimento_01.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esperimento di raster #1: tre rasterbar ottenute con una
;                 catena di interruzioni di raster non stabilizzate. Soluzione
;                 implementata con le macro di raster_tools.asm.
; CONTENUTO:      MAIN  Imposta la palette e avvia la catena di interruzioni
;                 IRQ1  Gestore IRQ: Raster bar rossa
;                 IRQ2  Gestore IRQ: Raster bar bianca
;                 IRQ3  Gestore IRQ: Raster bar verde
;                 IRQ4  Gestore IRQ: Ripristino sfondo
; DIPENDENZE:     "config_esperimento_01.asm"
;                 <c64/symbols.asm>
;                 <chip/cia.asm>
;                 <chip/vic_ii.asm>
;                 <chip/6510_tools.asm>
;                 <chip/raster_tools.asm>
;                 <system/standard.asm>
;                 <chip/vic_ii_tools.asm>
; REQUISITI ZP:   Nessuno
; ==============================================================================

; ------------------------------------------------------------------------------
; Uscita e processore
; ------------------------------------------------------------------------------

!to "esperimento 01.prg", cbm
!cpu 6510
!sl "esperimento_01.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_esperimento_01.asm", once

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
; ($0900-$0924) Gestore IRQ: Raster bar rossa
; ($0925-$0949) Gestore IRQ: Raster bar bianca
; ($094A-$096E) Gestore IRQ: Raster bar verde
; ($096F-$0993) Gestore IRQ: Ripristino sfondo

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <chip/6510_tools.asm>, once
!source <chip/raster_tools.asm>, once
!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

LINE1               = 100
LINE2               = LINE1+32
LINE3               = LINE2+32
LINE4               = LINE3+32

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #1"

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
;               avvia la catena di gestori IRQ1-IRQ4, che disegna le rasterbar.
;               Se il Kernal è abilitato (__DISABLE_KERNAL = 0) ritorna al BASIC
;               e le interruzioni continuano a disegnare le rasterbar. Se il
;               Kernal è disabilitato (__DISABLE_KERNAL = 1) non ritorna:
;               incrementa di continuo la prima cella dello schermo.
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

    +m_Init_Raster_System                               ; Inizializza la catena delle interruzioni.
    +m_Start_Raster_IRQ "UNSTABLE", LINE1, IRQ1

  !if (__DISABLE_KERNAL = 1) {

    .Loop_Increment_Cell:
      ; Un semplice effetto per mostrare che il computer non si
      ; blocca quando il Kernal è disabilitato.
      inc VICSCN                                        ; FOREVER
      jmp .Loop_Increment_Cell                          ; FOREVER: incrementa la prima cella dello schermo
  } else {

    .Exit_MAIN:
      rts
  }

!zone

; ------------------------------------------------------------------------------
; Subroutine del codice
; ------------------------------------------------------------------------------

  !align $00FF, 0, $00                                  ; Allinea i gestori delle interruzioni alla pagina.

; [MAPPA: Gestore IRQ: Raster bar rossa]
; ==============================================================================
; SUBROUTINE: IRQ1
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a LINE1: colora di rosso il bordo e lo sfondo e
;               prepara l'interruzione di raster successiva, a LINE2, il cui
;               gestore è IRQ2. I registri e i flag, salvati all'ingresso e
;               ripristinati all'uscita, risultano invariati per il codice
;               interrotto: il gestore consuma i 3 byte
;               salvati dall'interruzione.
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Uscita con rti o salto a IRQMIN
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  EXTCOL, BGCOL0, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq1

  IRQ1:
    +m_Enter_Raster_IRQ "UNSTABLE", LINE1               ; Rasterbar rossa.
    lda #VIC_RED
    sta EXTCOL
    sta BGCOL0

  .Exit_IRQ1:
    +m_Next_Raster_IRQ "UNSTABLE", LINE2, IRQ2, "FAST"

!zone

; [MAPPA: Gestore IRQ: Raster bar bianca]
; ==============================================================================
; SUBROUTINE: IRQ2
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a LINE2: colora di bianco il bordo e lo sfondo e
;               prepara l'interruzione di raster successiva, a LINE3, il cui
;               gestore è IRQ3. I registri e i flag, salvati all'ingresso e
;               ripristinati all'uscita, risultano invariati per il codice
;               interrotto: il gestore consuma i 3 byte
;               salvati dall'interruzione.
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Uscita con rti o salto a IRQMIN
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  EXTCOL, BGCOL0, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq2

  IRQ2:
    +m_Enter_Raster_IRQ "UNSTABLE", LINE2               ; Rasterbar bianca.
    lda #VIC_WHITE
    sta EXTCOL
    sta BGCOL0

  .Exit_IRQ2:
    +m_Next_Raster_IRQ "UNSTABLE", LINE3, IRQ3, "FAST"

!zone

; [MAPPA: Gestore IRQ: Raster bar verde]
; ==============================================================================
; SUBROUTINE: IRQ3
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a LINE3: colora di verde il bordo e lo sfondo e
;               prepara l'interruzione di raster successiva, a LINE4, il cui
;               gestore è IRQ4. I registri e i flag, salvati all'ingresso e
;               ripristinati all'uscita, risultano invariati per il codice
;               interrotto: il gestore consuma i 3 byte
;               salvati dall'interruzione.
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Uscita con rti o salto a IRQMIN
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  EXTCOL, BGCOL0, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq3

  IRQ3:
    +m_Enter_Raster_IRQ "UNSTABLE", LINE3               ; Rasterbar verde.
    lda #VIC_GREEN
    sta EXTCOL
    sta BGCOL0

  .Exit_IRQ3:
    +m_Next_Raster_IRQ "UNSTABLE", LINE4, IRQ4, "FAST"

!zone

; [MAPPA: Gestore IRQ: Ripristino sfondo]
; ==============================================================================
; SUBROUTINE: IRQ4
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a LINE4: colora di blu il bordo e lo sfondo, chiude
;               le rasterbar e richiude la catena: prepara l'interruzione di
;               raster successiva a LINE1, il cui gestore è IRQ1. I registri e i
;               flag, salvati all'ingresso e ripristinati all'uscita, risultano
;               invariati per il codice interrotto: il gestore consuma i 3 byte
;               salvati dall'interruzione.
;
;               Con il Kernal abilitato l'uscita passa per IRQHND, che scansiona
;               la tastiera e aggiorna i timer: le celle di lavoro del Kernal
;               che altera non hanno un contenuto garantito dopo la chiamata.
;               Con il Kernal disabilitato l'uscita è sempre veloce.
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Uscita con rti o salto a IRQHND
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  EXTCOL, BGCOL0, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
; ==============================================================================
!zone Irq4

  IRQ4:
    +m_Enter_Raster_IRQ "UNSTABLE", LINE4               ; Chiude le rasterbar e ricomincia la catena
                                                        ; delle interruzioni.
    lda #VIC_BLUE
    sta EXTCOL
    sta BGCOL0

  .Exit_IRQ4:
    +m_Next_Raster_IRQ "UNSTABLE", LINE1, IRQ1, "SLOW"  ; Almeno uno dei gestori IRQ della catena deve occuparsi della
                                                        ; scansione della tastiera.

!zone
