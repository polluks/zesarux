/*
    ZEsarUX  ZX Second-Emulator And Released for UniX
    Copyright (C) 2013 Cesar Hernandez Bano

    This file is part of ZEsarUX.

    ZEsarUX is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#ifndef COLECO_H
#define COLECO_H

#include "cpu.h"

extern z80_byte *coleco_vram_memory;


extern z80_byte coleco_read_vram_byte(z80_int address);



extern z80_byte *coleco_return_segment_address(z80_int direccion,int *tipo);



#define COLECO_SLOT_MEMORY_TYPE_ROM 0
#define COLECO_SLOT_MEMORY_TYPE_RAM 1
#define COLECO_SLOT_MEMORY_TYPE_EMPTY 2

extern void coleco_insert_rom_cartridge(char *filename);
extern void coleco_empty_romcartridge_space(void);
extern void coleco_out_port_vdp_data(z80_byte value);
extern void coleco_out_port_vdp_command_status(z80_byte value);

extern void coleco_set_keypad_mode(void);
extern void coleco_set_joystick_mode(void);
extern z80_byte coleco_get_controller_a(void);
extern z80_byte coleco_get_controller_b(void);

extern z80_byte coleco_in_port_vdp_data(void);
extern z80_byte coleco_in_port_vdp_status(void);

extern void coleco_reset(void);
extern void coleco_alloc_vram_memory(void);
extern void coleco_init_memory_tables(void);
extern void scr_refresca_pantalla_y_border_coleco(void);

extern char *coleco_get_string_memory_type(int tipo);

extern void screen_store_scanline_rainbow_coleco_border_and_display(void);




#endif
