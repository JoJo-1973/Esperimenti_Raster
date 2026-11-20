; ==============================================================================
; FILE:           esperimento_05.asm
; PROGETTO:       Esperimenti Raster (Esperimenti_Raster.c64)
; VERSIONE:       1.0.0
; AUTORE:         Stefano Priore
; TARGET:         ACME Assembler / MOS 6510 (Commodore 64)
; DESCRIZIONE:    Esperimento di raster #5: ricrea la schermata principale del
;                 programma CHAMP utilizzando però un raster stabile per
;                 evidenziare la linea di editing. Soluzione implementata con le
;                 macro di raster_tools.asm, della libreria chip.
; CONTENUTO:      MAIN              Disegna la schermata e avvia la catena IRQ
;                 PUT_ECM_CHAR      Driver di stampa in modo ECM
;                 PALETTE_SWAP      Gestore IRQ: evidenziazione della linea
;                 PALETTE_RESTORE   Gestore IRQ: ripristino dei colori
; DIPENDENZE:     "config_esperimento_05.asm"
;                 <c64/kernal.asm>
;                 <c64/symbols.asm>
;                 <chip/cia.asm>
;                 <chip/vic_ii.asm>
;                 <system/petscii.asm>
;                 <chip/raster_tools.asm>
;                 <system/standard.asm>
;                 <chip/vic_ii_tools.asm>
;                 <io/print_tools.asm>
; REQUISITI ZP:   __BG_COL, __VIC_MODEL, ZP_1
; ==============================================================================

; ------------------------------------------------------------------------------
; Uscita e processore
; ------------------------------------------------------------------------------

!to "esperimento 05.prg", cbm
!cpu 6510
!sl "esperimento_05.lbl"

; ------------------------------------------------------------------------------
; Configurazione
; ------------------------------------------------------------------------------

!source "config_esperimento_05.asm", once

; ------------------------------------------------------------------------------
; Simboli
; ------------------------------------------------------------------------------

!source <c64/kernal.asm>, once
!source <c64/symbols.asm>, once
!source <chip/cia.asm>, once
!source <chip/vic_ii.asm>, once
!source <system/petscii.asm>, once

; ------------------------------------------------------------------------------
; Mappa di memoria
; ------------------------------------------------------------------------------

BASIC_START         = BASTXT

; ($0801-$0827) Preambolo BASIC
; ($0828-$082A) Avvio
; ($082B-$088A) Moduli di libreria
; ($088B-$0892) Variabili globali
; ($0893-$0989) Codice principale
; ($098A-$09F4) Subroutine del codice
; ($09F5-$0A71) Gestore IRQ: Evidenziazione linea
; ($0A72-$0AEE) Gestore IRQ: Ripristino colori

; ------------------------------------------------------------------------------
; Macro
; ------------------------------------------------------------------------------

!source <chip/raster_tools.asm>, once
!source <system/standard.asm>, once

; ------------------------------------------------------------------------------
; Costanti globali
; ------------------------------------------------------------------------------

; Il cambio di colore deve avvenire in corrispondenza della 13
; riga dello schermo (linea 146) e, dopo 8 linee di raster, i
; colori ritornano ad essere quelli normali.
CURRENT_LINE_START  = 51+12*8-1
CURRENT_LINE_END    = CURRENT_LINE_START+8

; ------------------------------------------------------------------------------
; Inizio del codice
; ------------------------------------------------------------------------------

; [MAPPA: Preambolo BASIC]
*= BASIC_START
  +m_BASIC_Preamble 10, START, "ESPERIMENTO DI RASTER #5"

; [MAPPA: Avvio]
START:
  jmp MAIN

; ------------------------------------------------------------------------------
; Moduli di libreria
; ------------------------------------------------------------------------------

; [MAPPA: Moduli di libreria]
!source <chip/vic_ii_tools.asm>, once
!source <io/print_tools.asm>, once

; ------------------------------------------------------------------------------
; Variabili globali
; ------------------------------------------------------------------------------

; [MAPPA: Variabili globali]
; Colori di bordo, area messaggi, campi etichetta, opcode,
; operando e colore dei caratteri.
PALETTE_CHAMP:
  !byte VIC_PURPLE, VIC_YELLOW, VIC_BLACK, VIC_BLUE, VIC_GREEN, VIC_TRANSPARENT, VIC_TRANSPARENT, VIC_WHITE

; ------------------------------------------------------------------------------
; Codice principale
; ------------------------------------------------------------------------------

; [MAPPA: Codice principale]
; ==============================================================================
; SUBROUTINE: MAIN
; ------------------------------------------------------------------------------
; Descrizione:  Programma principale: imposta i colori del VIC-II con la tabella
;               PALETTE_CHAMP, attiva il modo Colore di Sfondo Esteso, cancella
;               lo schermo e riempie le linee 0-22 con i caratteri dei tre campi
;               (etichetta, opcode e operando), poi disegna alcune righe di
;               finto codice e la scritta <ASSEMBLE> per rendere la schermata
;               più realistica. Infine inizializza il sistema delle interruzioni
;               di raster e avvia l'interruzione stabilizzata PALETTE_SWAP. Non
;               ritorna: attende le interruzioni in un ciclo senza fine.
;
;               Le subroutine CLRSCR e PLOT del Kernal alterano proprie celle di
;               lavoro, il cui contenuto non è garantito dopo la chiamata.
;
; Input:
;   - Nessuno
;
; Output:
;   - .PC (2 byte, CPU) : Non ritorna al chiamante
;
; Variazione Stack (.S):
;   - Stabile
;
; Registri Modificati:  .A, .X, .Y, .P (Negative, oVerflow, Interrupt, Zero,
;                       Carry), INDEX2, ZP_1, EXTCOL, BGCOL0, BGCOL1, BGCOL2,
;                       BGCOL3, SPMC0, SPMC1, COLOR, __BG_COL, RVS, __VIC_MODEL,
;                       CIAICR, CI2ICR, VICIRQ, IRQMSK, RASTER, SCROLY,
;                       VICSCN (1000 byte),
;                       R6510 (se __DISABLE_KERNAL = 1),
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/raster_tools.asm>
;                       <chip/vic_ii_tools.asm>
;                       <io/print_tools.asm>
;                       <system/petscii.asm>
; ==============================================================================
!zone Main

  MAIN:
    +m_VIC_Ext_Color_On

    lda #<PALETTE_CHAMP
    ldx #>PALETTE_CHAMP
    jsr VIC_PALETTE

    lda #<VICSCN                      ; Imposta un puntatore alla linea 0.
    sta ZP_1
    lda #>VICSCN
    sta ZP_1+1

    jsr CLRSCR                        ; Colora lo schermo di giallo.

    ; I campi occupano le linee 0-22.
    ldx #23                           ; FOR (Inizializzazione)

  .Loop_Line:
    ; Indice alla colonna.
    ldy #$00                          ; FOR (Corpo); FOR (Inizializzazione)

  .Loop_Field:
    ; Carattere del campo etichetta (colonne 0-7).
    lda #(PETSCII_SPACE or %01000000) ; FOR (Corpo)

    cpy #8
    bcc .Plot_Field

    lda #(PETSCII_SPACE or %10000000) ; Carattere del campo opcode (colonne 8-12).

    cpy #13
    bcc .Plot_Field

    lda #(PETSCII_SPACE or %11000000) ; Carattere del campo operando (colonne 13-39).

  .Plot_Field:
    sta (ZP_1),y                      ; Scrivi il carattere appropriato nella memoria video.
    iny                               ; NEXT: incrementa l'indice

    cpy #40
    bcc .Loop_Field                   ; NEXT: ripete finché .Y è minore di 40

  .Update_Line_Pointer:
    ; Una volta terminata la linea attuale somma 40 al puntatore
    ; così da puntare all'inizio della linea sottostante.
    tya
    clc
    adc ZP_1
    sta ZP_1

    bcc .Next_Line

    inc ZP_1+1

  .Next_Line:
    dex                               ; NEXT: decrementa il contatore
    bne .Loop_Line                    ; NEXT: ripete finché .X è diverso da 0

    ; Disegna del finto codice per rendere la schermata un po'
    ; più realistica...
    jsr PRINT_IMM
    !text 11, 8, ECM_BG2, " ORG ", ECM_BG3, " $C000", ECM_BG0, $00
    jsr PRINT_IMM
    !text 12, 0, ECM_BG1, " START  ", ECM_BG2, " LDA ", ECM_BG3, " #$00", ECM_BG0, $00
    jsr PRINT_IMM
    !text 13, 8, ECM_BG2, " RTS ", ECM_BG0, $00
    jsr PRINT_IMM
    !text 24, 0, ECM_BG0, PETSCII_BLACK, "<ASSEMBLE>", ECM_BG3, " ", ECM_BG0, PETSCII_WHITE, PETSCII_HOME, $00

    +m_Init_Raster_System             ; Inizializza la catena delle interruzioni.
    +m_Start_Raster_IRQ "STABLE", CURRENT_LINE_START, PALETTE_SWAP

  .Loop_Wait:
    jmp .Loop_Wait                    ; FOREVER; FOREVER: attende le interruzioni

!zone

; ------------------------------------------------------------------------------
; Subroutine del codice
; ------------------------------------------------------------------------------

; [MAPPA: Subroutine del codice]
; ==============================================================================
; SUBROUTINE: PUT_ECM_CHAR
; ------------------------------------------------------------------------------
; Descrizione:  Driver di stampa del programma, richiamato dalle subroutine di
;               stampa attraverso il punto di personalizzazione __PUT_CHAR:
;               stampa in modo Colore di Sfondo Esteso il carattere PETSCII in
;               .A, con il colore di sfondo scelto da __BG_COL, e restituisce
;               .A, .X e .Y invariati. I codici ECM_BG0-ECM_BG3 cambiano il
;               colore di sfondo senza stampare nulla. Il lavoro lo fa la macro
;               m_Put_ECM_Char [NOTA #02 in <io/print_tools.asm>].
;
; Input:
;   - .A (1 byte, CPU)      : Codice PETSCII da stampare
;   - __BG_COL (1 byte, ZP) : Selettore del colore di sfondo (0-3)
;
; Output:
;   - __BG_COL (1 byte, ZP) : Nuovo selettore (se il codice è ECM_BG0-ECM_BG3)
;   - RVS (1 byte, ZP)      : Modo reverse (bit #1 di __BG_COL), se il codice è
;                             stampabile
;
; Variazione Stack (.S):
;   - Stabile
;
; Registri Modificati:  .P (Negative, oVerflow, Zero, Carry), __BG_COL, RVS
; Dipendenze Esterne:   <c64/kernal.asm>
;                       <c64/symbols.asm>
;                       <io/print_tools.asm>
; ==============================================================================
!zone Put_ECM_Char

  PUT_ECM_CHAR:
    +m_Put_ECM_Char

  .Exit_PUT_ECM_CHAR:
    rts

!zone

; [MAPPA: Gestore IRQ: Evidenziazione linea]
; ==============================================================================
; SUBROUTINE: PALETTE_SWAP
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a CURRENT_LINE_START: interruzione di raster
;               stabilizzata che scrive in BGCOL1, BGCOL2 e BGCOL3 i colori
;               della linea evidenziata (grigio medio, azzurro chiaro e verde
;               chiaro), ciascuno subito dopo che il campo corrispondente
;               (etichetta, opcode, operando) è stato disegnato. Prepara
;               l'interruzione di raster successiva, a CURRENT_LINE_END, il cui
;               gestore è PALETTE_RESTORE. I registri e i flag, salvati
;               all'ingresso e ripristinati all'uscita, risultano invariati per
;               il codice interrotto. Sullo stack il gestore consuma i 3 byte
;               che l'interruzione ha salvato.
;
; Input:
;   - __VIC_MODEL (1 byte, ZP) : Modello VIC-II (vedi m_Init_Raster_System)
;
; Output:
;   - .PC (2 byte, CPU)        : Uscita con rti o salto a IRQMIN
;
; Variazione Stack (.S):
;   - Incrementato di 3 byte
;
; Registri Modificati:  BGCOL1, BGCOL2, BGCOL3, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
;                       <system/standard.asm>
; ==============================================================================
!zone Palette_Swap

  PALETTE_SWAP:
    +m_Enter_Stable_IRQ CURRENT_LINE_START

    +m_Raster_Grip                    ; 03  (+7)
    +m_Delay_5n1 ".X", 6              ; 10  (+31)
    nop                               ; 41  (+2)
    nop                               ; 43  (+2)

    lda #VIC_MEDIUM_GREY              ; 45  (+2)
    sta BGCOL1                        ; 47  (+4)     La scrittura di BGCOL1 avviene esattamente al ciclo 50,
                                      ;              quando il campo etichetta è stato già disegnato.

    lda #VIC_LIGHT_BLUE               ; 51  (+2)
    sta BGCOL2                        ; 53  (+4)     La scrittura di BGCOL2 avviene esattamente al ciclo 56,
                                      ;              quando il campo opcode è stato già disegnato.

    lda #VIC_LIGHT_GREEN              ; 57  (+2)
    sta BGCOL3                        ; 59  (+4)     La scrittura di BGCOL3 avviene esattamente al ciclo 62,
                                      ;              quando il campo operando è stato già disegnato.
                                      ; 63  ...

  .Exit_PALETTE_SWAP:
    +m_Next_Stable_IRQ CURRENT_LINE_END, PALETTE_RESTORE, "FAST"

!zone

; [MAPPA: Gestore IRQ: Ripristino colori]
; ==============================================================================
; SUBROUTINE: PALETTE_RESTORE
; ------------------------------------------------------------------------------
; Descrizione:  Gestore IRQ a CURRENT_LINE_END: interruzione di raster
;               stabilizzata che riporta BGCOL1, BGCOL2 e BGCOL3 ai colori
;               normali dei campi (nero, blu e verde), con la stessa
;               temporizzazione di PALETTE_SWAP. Prepara l'interruzione di
;               raster successiva, a CURRENT_LINE_START, il cui gestore è
;               PALETTE_SWAP, e termina con l'uscita lenta (IRQHND), che
;               scansiona la tastiera e aggiorna i timer. I registri e i flag,
;               salvati all'ingresso e ripristinati all'uscita, risultano
;               invariati per il codice interrotto. Sullo stack il gestore
;               consuma i 3 byte che l'interruzione ha salvato.
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
; Registri Modificati:  BGCOL1, BGCOL2, BGCOL3, RASTER, SCROLY, VICIRQ,
;                       IRBVEC (se __DISABLE_KERNAL = 1),
;                       CINV (se __DISABLE_KERNAL = 0)
; Dipendenze Esterne:   <c64/symbols.asm>
;                       <chip/raster_tools.asm>
;                       <chip/vic_ii.asm>
;                       <system/standard.asm>
; ==============================================================================
!zone Palette_Restore

  PALETTE_RESTORE:
    +m_Enter_Stable_IRQ CURRENT_LINE_END

    +m_Raster_Grip                    ; 03  (+7)
    +m_Delay_5n1 ".X", 6              ; 10  (+31)
    nop                               ; 41  (+2)
    nop                               ; 43  (+2)

    lda #VIC_BLACK                    ; 45  (+2)
    sta BGCOL1                        ; 47  (+4)     La scrittura di BGCOL1 avviene esattamente al ciclo 50,
                                      ;              quando il campo etichetta è stato già disegnato.

    lda #VIC_BLUE                     ; 51  (+2)
    sta BGCOL2                        ; 53  (+4)     La scrittura di BGCOL2 avviene esattamente al ciclo 56,
                                      ;              quando il campo opcode è stato già disegnato.

    lda #VIC_GREEN                    ; 57  (+2)
    sta BGCOL3                        ; 59  (+4)     La scrittura di BGCOL3 avviene esattamente al ciclo 62,
                                      ;              quando il campo operando è stato già disegnato.
                                      ; 63  ...

  .Exit_PALETTE_RESTORE:
    ; Almeno uno dei gestori IRQ della catena deve occuparsi della
    ; scansione della tastiera.
    +m_Next_Stable_IRQ CURRENT_LINE_START, PALETTE_SWAP, "SLOW"

!zone
