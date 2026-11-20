; ==============================================================================
; FILE:           esperimento_03.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esperimento di raster #3: 16 linee di raster colorate nel
;                 bordo ottenute con un'interruzione stabilizzata. Soluzione
;                 implementata con le macro di raster_tools.asm. È una replica
;                 di quanto fatto in ready64_04.asm.
; CONTENUTO:      MAIN  Imposta la palette e avvia l'interruzione di raster
;                 IRQ1  Gestore IRQ: Raster bar multicolore
; DIPENDENZE:     "config_esperimento_03.asm"
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

!to "esperimento 03.prg", cbm
!cpu 6510
!sl "esperimento_03.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_esperimento_03.asm", once

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
; ($0900-$099E) Gestore IRQ: Raster bar multicolore

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <chip/6510_tools.asm>, once
!source <chip/raster_tools.asm>, once
!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

RASTER_START        = 30
RASTER_HEIGHT       = 16

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #3"

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
;               avvia l'interruzione stabilizzata IRQ1, che colora 16 linee del
;               bordo. Se il Kernal è abilitato (__DISABLE_KERNAL = 0) ritorna
;               al BASIC e l'interruzione continua a colorare il bordo. Se il
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

    +m_Init_Raster_System                                     ; Inizializza la catena delle interruzioni.
    +m_Start_Raster_IRQ "STABLE", RASTER_START-1, IRQ1

  !if (__DISABLE_KERNAL = 1) {

    .Loop_Increment_Cell:
      ; Un semplice effetto per mostrare che il computer non si
      ; blocca quando il Kernal è disabilitato.
      inc VICSCN                                              ; FOREVER
      jmp .Loop_Increment_Cell                                ; FOREVER: incrementa la prima cella dello schermo
  } else {

    .Exit_MAIN:
      rts
  }

!zone

; ------------------------------------------------------------------------------
; Subroutine del codice
; ------------------------------------------------------------------------------

  !align $00FF, 0, $00                                        ; Allinea il gestore delle interruzioni alla pagina.

; [MAPPA: Gestore IRQ: Raster bar multicolore]
; ==============================================================================
; SUBROUTINE: IRQ1
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a RASTER_START-1: colora il bordo con 16 linee di
;               raster consecutive, una per ciascuno dei 16 colori, in ordine
;               decrescente, e poi ripristina il blu. Prepara l'interruzione di
;               raster successiva, ancora a RASTER_START-1, il cui gestore è
;               IRQ1. I registri e i flag, salvati all'ingresso e ripristinati
;               all'uscita, risultano invariati per il codice interrotto.
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
; Registri Modificati:  EXTCOL, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
;                       <system/standard.asm>
; ==============================================================================
!zone Irq1

  IRQ1:
    +m_Enter_Raster_IRQ "STABLE", RASTER_START-1

  .Waste_Line:
    +m_Raster_Grip                                            ; 03  (+7)     Queste istruzioni servono a bruciare cicli in modo che
    +m_Delay_5n1 ".X", 7                                      ; 10  (+36)    l'istruzione sta EXTCOL inizi la sua esecuzione al ciclo 59
    cmp UNUSED                                                ; 46  (+3)     e termini ESATTAMENTE al ciclo 62 perché è esattamente al
                                                              ;              ciclo 62 (+eventuali NTSC) che EXTCOL verrà sovrascritto. Se
                                                              ;              i calcoli sono giusti il cambio di colore avverrà
                                                              ;              precisamente all'inizio della linea successiva, e così per
                                                              ;              tutte le altre linee di raster successive.

    ldy #RASTER_HEIGHT                                        ; 49  (+2)     FOR (Inizializzazione)

  .Loop_Fill_Line:
    tya                                                       ; 51  (+2)     FOR (Corpo)
    eor #$FF                                                  ; 53  (+2)
    clc                                                       ; 55  (+2)
    adc #17                                                   ; 57  (+2)
    sta EXTCOL                                                ; 59  (+4)     La scrittura di EXTCOL avviene esattamente al ciclo 62.

    +m_Raster_Grip                                            ; 63  (+7)

    +m_Delay_5n1 ".X", 7                                      ; 07  (+36)
    cmp UNUSED                                                ; 43  (+3)

    dey                                                       ; 46  (+2)     NEXT: conta le linee di raster
    bne .Loop_Fill_Line                                       ; 48  (+3/2)   NEXT: ripete finché .Y è diverso da 0

    cmp UNUSED                                                ; 50  (+3)
    nop                                                       ; 53  (+2)
    nop                                                       ; 55  (+2)

    lda #VIC_BLUE                                             ; 57  (+2)
    sta EXTCOL                                                ; 59  (+4)     La scrittura di EXTCOL avviene esattamente al ciclo 62.
                                                              ; 63  ...

  .Exit_IRQ1:
    +m_Next_Raster_IRQ "STABLE", RASTER_START-1, IRQ1, "SLOW" ; L'unico gestore IRQ della catena deve occuparsi anche della
                                                              ; scansione della tastiera.

!zone
