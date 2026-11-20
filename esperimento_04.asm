; ==============================================================================
; FILE:           esperimento_04.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esperimento di raster #4: riempie lo schermo di caratteri e ne
;                 fa scorrere una parte in orizzontale con un'interruzione di
;                 raster stabilizzata. Soluzione implementata con le macro di
;                 raster_tools.asm, della libreria chip.
; CONTENUTO:      MAIN          Riempie lo schermo e avvia la catena IRQ
;                 SCROLL_START  Gestore IRQ: inizio dell'area di scorrimento
;                 SCROLL_STOP   Gestore IRQ: arresto dell'area di scorrimento
; DIPENDENZE:     "config_esperimento_04.asm"
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

!to "esperimento 04.prg", cbm
!cpu 6510
!sl "esperimento_04.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_esperimento_04.asm", once

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
; ($0844-$084C) Variabili globali
; ($084D-$08FF) Codice principale
; ($0900-$0995) Gestore IRQ: Inizio dell'area di scorrimento
; ($0996-$0A17) Gestore IRQ: Arresto dell'area di scorrimento

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <chip/6510_tools.asm>, once
!source <chip/raster_tools.asm>, once
!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

RASTER_START        = 51+(2*8)-1
RASTER_STOP         = RASTER_START+(15*8)

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #4"

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
_XSCROLL:
  !byte 0

PALETTE:
  !byte VIC_BLUE, VIC_BLUE, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_WHITE

; ------------------------------------------------------------------------------
; Codice principale
; ------------------------------------------------------------------------------

; [MAPPA: Codice principale]
; ==============================================================================
; SUBROUTINE: MAIN
; ------------------------------------------------------------------------------
; Descrizione:  Programma principale: imposta i colori del VIC-II con la tabella
;               PALETTE, cancella lo schermo e lo riempie con i codici di
;               carattere da 0 a 255, ripetuti, azzera il contatore _XSCROLL e
;               lo scorrimento orizzontale fine di SCROLX, inizializza il
;               sistema delle interruzioni di raster e avvia l'interruzione
;               stabilizzata SCROLL_START. Se il Kernal è abilitato
;               (__DISABLE_KERNAL = 0) ritorna al BASIC e le interruzioni
;               continuano a far scorrere la parte di schermo. Se il Kernal è
;               disabilitato (__DISABLE_KERNAL = 1) non ritorna: incrementa di
;               continuo la prima cella dello schermo.
;
;               La subroutine CLRSCR del Kernal altera proprie celle di lavoro,
;               il cui contenuto non è garantito dopo la chiamata.
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
;                       VICIRQ, IRQMSK, RASTER, SCROLX, SCROLY, _XSCROLL,
;                       VICSCN (1000 byte),
;                       R6510 (se __DISABLE_KERNAL = 1),
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
;                       <chip/vic_ii_tools.asm>
; ==============================================================================
!zone Main

  MAIN:
    lda #<PALETTE
    ldx #>PALETTE
    jsr VIC_PALETTE

    jsr CLRSCR
    ldx #0                                                          ; FOR (Inizializzazione)

  .Loop_Fill_Screen:
    txa                                                             ; FOR (Corpo)

    sta VICSCN,x
    sta VICSCN+$100,x
    sta VICSCN+$200,x
    sta VICSCN+$2E8,x

    inx                                                             ; NEXT: incrementa l'indice
    bne .Loop_Fill_Screen                                           ; NEXT: ripete finché .X è diverso da 0

    stx _XSCROLL                                                    ; Inizializza _XSCROLL.

    lda SCROLX
    and #%11111000
    sta SCROLX

    +m_Init_Raster_System                                           ; Inizializza la catena delle interruzioni.
    +m_Start_Raster_IRQ "STABLE", RASTER_START, SCROLL_START

  !if (__DISABLE_KERNAL = 1) {

    .Loop_Increment_Cell:
      ; Un semplice effetto per mostrare che il computer non si
      ; blocca quando il Kernal è disabilitato.
      inc VICSCN                                                    ; FOREVER
      jmp .Loop_Increment_Cell                                      ; FOREVER: incrementa la prima cella dello schermo
  } else {

    .Exit_MAIN:
      rts
  }

!zone

; ------------------------------------------------------------------------------
; Subroutine del codice
; ------------------------------------------------------------------------------

  !align $00FF, 0, $00                                              ; Allinea i gestori delle interruzioni alla pagina.

; [MAPPA: Gestore IRQ: Inizio dell'area di scorrimento]
; ==============================================================================
; SUBROUTINE: SCROLL_START
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a RASTER_START: decrementa il contatore _XSCROLL (da
;               7 a 0, poi lo riporta a 7) e lo scrive nei 3 bit di scorrimento
;               orizzontale fine di SCROLX, così che la parte di schermo
;               compresa tra RASTER_START e RASTER_STOP scorra di un pixel a
;               ogni schermata. Prepara l'interruzione di raster successiva, a
;               RASTER_STOP, il cui gestore è SCROLL_STOP. I registri e i flag,
;               salvati all'ingresso e ripristinati all'uscita, risultano
;               invariati per il codice interrotto. Sullo stack il gestore
;               consuma i 3 byte che l'interruzione ha salvato.
;
;               Dopo il decremento il codice si biforca: se _XSCROLL è negativo
;               viene ripristinato al valore 7; altrimenti il ramo che non fa
;               niente è dirottato verso istruzioni inutili e poi si ricongiunge
;               al flusso principale. È fondamentale che i due rami consumino lo
;               stesso numero di cicli. Ramo del ripristino: bpl non preso (+2),
;               lda (+2), sta (+4), in tutto 8 cicli. Ramo che non fa niente:
;               bpl preso (+3), nop (+2), jmp di ricongiungimento (+3), in tutto
;               8 cicli. Entrambi partono al ciclo 41 e si ricongiungono al
;               ciclo 49. Per questo la routine non deve attraversare confini di
;               pagina, perché aggiungerebbe un ciclo al bpl.
;               L'uscita usa bne come salto sempre preso: i bit #6-#7 di
;               SCROLX non sono usati e si leggono come 1, quindi dopo and e
;               ora il flag Z vale 0 anche con 38 colonne (verificato: $D016
;               vale $C8 con 40 colonne).
;
; Input:
;   - __VIC_MODEL (1 byte, ZP) : Modello VIC-II (vedi m_Init_Raster_System)
;   - _XSCROLL (1 byte, RAM)   : Contatore dello scorrimento fine, da 0 a 7
;
; Output:
;   - .PC (2 byte, CPU)        : Uscita con rti o salto a IRQMIN
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  SCROLX, _XSCROLL, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
;                       <system/standard.asm>
; ==============================================================================
!zone Scroll_Start

  SCROLL_START:
    +m_Enter_Raster_IRQ "STABLE", RASTER_START

    +m_Delay_5n1 ".Y", 4                                            ; 03  (+21)
    nop                                                             ; 24  (+2)
    nop                                                             ; 26  (+2)
    +m_Raster_Grip                                                  ; 28  (+7)

    dec _XSCROLL                                                    ; 35  (+6)
    bpl .Else_Waste_Cycles                                          ; 41  (+3/2)   IF: _XSCROLL è negativo

    lda #7                                                          ; 43  (+2)
    sta _XSCROLL                                                    ; 45  (+4)

  .Update_Scroll_Register:
    lda SCROLX                                                      ; 49  (+4)
    and #%11111000                                                  ; 53  (+2)
    ora _XSCROLL                                                    ; 55  (+4)
    sta SCROLX                                                      ; 59  (+4)     La scrittura di SCROLX avviene esattamente al ciclo 62.
    bne .Exit_SCROLL_START                                          ; 63  (+3)
                                                                    ; 03  ...

  .Else_Waste_Cycles:
    nop                                                             ; 44  (+2)     ELSE
    jmp .Update_Scroll_Register                                     ; 46  (+3)

  .Exit_SCROLL_START:
    +m_Next_Raster_IRQ "STABLE", RASTER_STOP, SCROLL_STOP, "FAST"

!zone

; [MAPPA: Gestore IRQ: Arresto dell'area di scorrimento]
; ==============================================================================
; SUBROUTINE: SCROLL_STOP
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a RASTER_STOP: riporta a zero lo scorrimento
;               orizzontale fine di SCROLX, per cui la parte di schermo sotto
;               RASTER_STOP non scorre. Prepara l'interruzione di raster
;               successiva, a RASTER_START, il cui gestore è SCROLL_START. I
;               registri e i flag, salvati all'ingresso e ripristinati
;               all'uscita, risultano invariati per il codice interrotto. Sullo
;               stack il gestore consuma i 3 byte che l'interruzione ha salvato.
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
; Registri Modificati:  SCROLX, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
;                       <system/standard.asm>
; ==============================================================================
!zone Scroll_Stop

  SCROLL_STOP:
    +m_Enter_Raster_IRQ "STABLE", RASTER_STOP

    +m_Delay_5n1 ".Y", 8                                            ; 03  (+41)
    nop                                                             ; 44  (+2)
    +m_Raster_Grip                                                  ; 46  (+7)
    lda SCROLX                                                      ; 53  (+4)
    and #%11111000                                                  ; 57  (+2)
    sta SCROLX                                                      ; 59  (+4)     La scrittura di SCROLX avviene esattamente al ciclo 62.
                                                                    ; 63  ...

  .Exit_SCROLL_STOP:
    +m_Next_Raster_IRQ "STABLE", RASTER_START, SCROLL_START, "SLOW" ; Almeno uno dei gestori IRQ della catena deve occuparsi della
                                                                    ; scansione della tastiera.

!zone
