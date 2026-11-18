; ESPERIMENTO DI RASTER #5: Questo programma ricrea la schermata principale del programma CHAMP utilizzando però un raster stabile per evidenziare la linea di editing.

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_esperimento_05.asm"

!source <c64/symbols.asm>
!source <c64/kernal.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <io/chars.asm>
!source <system/branch.asm>
!source <system/petscii.asm>
!source <system/standard.asm>
!source <mem/mem16.asm>
!source <chip/raster_tools.asm>

BASIC_START         = BASTXT

*= BASIC_START
+m_BASIC_Preamble 10,START,"ESPERIMENTO DI RASTER #5"



CURRENT_LINE_START = 51+12*8-1         ; Il cambio di colore deve avvenire in corrispondenza della 13 riga dello schermo (linea 146)
CURRENT_LINE_END = CURRENT_LINE_START+8 ; e dopo 8 linee di raster i colori ritornano ad essere quelli normali.

PALETTE_CHAMP:
; Colori di bordo, area messaggi, campi etichetta, opcode, operando e colore dei caratteri.
  !byte VIC_PURPLE,VIC_YELLOW,VIC_BLACK,VIC_BLUE,VIC_GREEN,VIC_TRANSPARENT,VIC_TRANSPARENT,VIC_WHITE

START:
  jmp MAIN
!source <chip/vic_ii_tools.asm>
!source <io/print_tools.asm>

MAIN:
  +m_VIC_Ext_Color_On

  lda #<PALETTE_CHAMP
  ldx #>PALETTE_CHAMP
  jsr VIC_PALETTE

  lda #<VICSCN                  ; Imposta un puntatore alla linea 0.
  sta ZP_1
  lda #>VICSCN
  sta ZP_1+1

  jsr CLRSCR                    ; Colora lo schermo di giallo.

  ldx #23                       ; I campi occupano le linee 0-22.

.Loop_Line:
  ldy #$00                      ; Indice alla colonna

.Loop_Field:
  lda #(PETSCII_SPACE or %01000000)        ; Carattere del campo etichetta (colonne 0-7).
  cpy #8
  bcc .Plot_Field

  lda #(PETSCII_SPACE or %10000000)        ; Carattere del campo opcode (colonne 8-12).
  cpy #13
  bcc .Plot_Field

  lda #(PETSCII_SPACE or %11000000)        ; Carattere del campo operando (colonne 13-39).

.Plot_Field:
  sta (ZP_1),y                  ; Scrivi il carattere appropriato nella memoria video.
  iny
  cpy #40
  bcc .Loop_Field

.Next_Line:
  tya                           ; Una volta terminata la linea attuale somma 40 al puntatore così da puntare all'inizio della linea sottostante.
  clc
  adc ZP_1
  sta ZP_1
  bcc .Check_Last_Line
  inc ZP_1+1

.Check_Last_Line:
  dex                           ; Se ci sono ancora linee, itera.
  bne .Loop_Line

jsr PRINT_IMM                   ; Disegna del finto codice per rendere la schermata un po' più realistica...
!text 11,8,ECM_BG2," ORG ",ECM_BG3," $C000",ECM_BG0,0
jsr PRINT_IMM
!text 12,0,ECM_BG1," START  ",ECM_BG2," LDA ",ECM_BG3," #$00",ECM_BG0,0
jsr PRINT_IMM
!text 13,8,ECM_BG2," RTS ",ECM_BG0,0
jsr PRINT_IMM
!text 24,0,ECM_BG0,PETSCII_BLACK,"<ASSEMBLE>",ECM_BG3," ",ECM_BG0,PETSCII_WHITE,PETSCII_HOME,0



  +m_Init_Raster_System    ; Inizializza la catena delle interruzioni
  +m_Start_Raster_IRQ "STABLE", CURRENT_LINE_START, PALETTE_SWAP

.Wait:
  jmp .Wait

PUT_ECM_CHAR:
  +m_Put_ECM_Char

.Exit_PUT_ECM_CHAR:
  rts

; [MAPPA: Gestore IRQ: Evidenziazione linea]
PALETTE_SWAP:
  +m_Enter_Stable_IRQ CURRENT_LINE_START
  +m_Raster_Grip                ; 3 (+7)
  +m_Delay_5n1 ".X",6           ; 10 (+31)
  nop                           ; 41 (+2)
  nop                           ; 43 (+2)

  lda #VIC_MEDIUM_GREY           ; 45 (+2)
  sta BGCOL1                    ; 47 (+4) La scrittura di BGCOL1 avviene esattamente al ciclo 50, quando il campo etichetta è stato già disegnato.

  lda #VIC_LIGHT_BLUE           ; 51 (+2)
  sta BGCOL2                    ; 53 (+4) La scrittura di BGCOL2 avviene esattamente al ciclo 56, quando il campo opcode è stato già disegnato.

  lda #VIC_LIGHT_GREEN          ; 57 (+2)
  sta BGCOL3                    ; 59 (+4) La scrittura di BGCOL3 avviene esattamente al ciclo 62, quando il campo operando è stato già disegnato.

  +m_Next_Stable_IRQ CURRENT_LINE_END, PALETTE_RESTORE, "FAST"

; [MAPPA: Gestore IRQ: Ripristino colori]
PALETTE_RESTORE:
  +m_Enter_Stable_IRQ CURRENT_LINE_END
  +m_Raster_Grip                ; 3 (+7)
  +m_Delay_5n1 ".X",6           ; 10 (+31)
  nop                           ; 41 (+2)
  nop                           ; 43 (+2)

  lda #VIC_BLACK           ; 45 (+2)
  sta BGCOL1                    ; 47 (+4) La scrittura di BGCOL1 avviene esattamente al ciclo 50, quando il campo etichetta è stato già disegnato.

  lda #VIC_BLUE           ; 51 (+2)
  sta BGCOL2                    ; 53 (+4) La scrittura di BGCOL2 avviene esattamente al ciclo 56, quando il campo opcode è stato già disegnato.

  lda #VIC_GREEN          ; 57 (+2)
  sta BGCOL3                    ; 59 (+4) La scrittura di BGCOL3 avviene esattamente al ciclo 62, quando il campo operando è stato già disegnato.

  +m_Next_Stable_IRQ CURRENT_LINE_START, PALETTE_SWAP, "SLOW" ; Almeno uno dei gestori IRQ della catena deve occuparsi della scansione della tastiera.
