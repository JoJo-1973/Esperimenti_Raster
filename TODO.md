# TODO - Esperimenti Raster

Versione attuale: nessuna (raccolta di esperimenti sul raster del VIC-II).

## In corso

## Da fare

## Fatto

- 2026-11-20 Adeguato lo stile di `ready64_01.asm` … `ready64_06.asm` alla guida A 2026-11-20 (struttura del sorgente principale, contratti, mappa di memoria, `, once` ripristinato, tolto `PROVA TEMPORANEA`) e portata la versione a 1.0.0. In `ready64_06.asm` le temporizzazioni di `IRQ_1` sono state misurate in VICE x64sc: ingresso a 38-39 cicli, `stx` a 60 (a 54 nel caso raro).
- 2026-11-20 Adeguato lo stile di `esperimento_01.asm` … `esperimento_05.asm` alla guida A 2026-11-20 (struttura del sorgente principale, contratti, mappa di memoria, `, once`) e portata la versione a 1.0.0.
- 2026-11-20 Verificato il file di progetto `Esperimenti_Raster.c64`: nome della Soluzione e gruppi di libreria corretti.
- 2026-11-17 Usato `__DISABLE_KERNAL` al posto di `__KERNAL_STATUS` in `esperimento_01.asm` … `esperimento_04.asm`.
- 2026-11-17 Riscritto `esperimento_05.asm` con le macro del modulo `raster_tools.asm`.
- 2026-11-17 Resi compilabili tutti i programmi (`ready64_01.asm` … `ready64_06.asm`, `esperimento_01.asm` … `esperimento_05.asm`): nomi delle macro con il prefisso `m_`, inclusione del proprio `config_<programma>.asm`, `BASIC_START` e `*= BASIC_START`; in `esperimento_05.asm` `UNUSED` sostituito da `UNUSE2` (locazione in RAM, 6 cicli).
- 2026-11-17 Creati i file di configurazione `config_esperimento_01.asm` … `config_esperimento_05.asm` e `config_ready64_01.asm` … `config_ready64_06.asm`, copie del template con `__DISABLE_KERNAL = 1` per `esperimento_02.asm` ed `esperimento_03.asm` (P422).
- 2026-11-17 Aggiornati i percorsi delle librerie in `esperimento_01.asm` … `esperimento_05.asm` (`6510_tools` e `raster_tools` ora in `chip/`; gruppo di libreria davanti ai file di `esperimento_05.asm`).
- 2026-11-17 Cartella rinominata da `Raster_Experiments` a `Esperimenti_Raster`; aggiunti `.gitattributes`, `.gitignore` e questo file.
