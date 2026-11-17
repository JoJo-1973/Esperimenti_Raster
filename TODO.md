# TODO - Esperimenti Raster

Versione attuale: nessuna (raccolta di esperimenti sul raster del VIC-II).

## In corso

## Da fare

- [stile] Aggiornare i percorsi delle librerie: `esperimento_01.asm` … `esperimento_04.asm` includono `<system/6510_tools.asm>` e `<system/raster_tools.asm>`, ora in `chip/`; `esperimento_05.asm` include `<symbols.asm>`, `<kernal.asm>`, `<vic_ii.asm>`, `<cia.asm>` e `<standard.asm>` senza il gruppo di libreria (`c64/`, `chip/`, `system/`).
- [stile] Adeguare alla guida di stile i sorgenti `esperimento_01.asm` … `esperimento_05.asm` e `ready64_01.asm` … `ready64_06.asm` (intestazioni, contratti, commenti), un file alla volta.
- [da verificare] Il file di progetto `Esperimenti_Raster.c64` porta ancora al suo interno il nome `Raster_Experiments` e non fa riferimento ai gruppi di libreria `io` e `math`: controllarlo in C64Studio.

## Fatto

- 2026-11-17 Cartella rinominata da `Raster_Experiments` a `Esperimenti_Raster`; aggiunti `.gitattributes`, `.gitignore` e questo file.
