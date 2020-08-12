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

#ifndef SETTINGS_H
#define SETTINGS_H

#include "cpu.h"

#define MAX_KMOUSE_SENSITIVITY 10

#define DEFAULT_ADV_KEYBOARD_KEY_LENGTH 50

extern z80_bit menu_debug_registers_if_showscan;

extern z80_bit debug_settings_show_screen;

extern int debug_registers;

extern z80_bit debug_shows_invalid_opcode;

extern z80_bit debug_breakpoints_cond_behaviour;

extern int remote_debug_settings;

extern int debug_show_fired_breakpoints_type;

extern int verbose_level;

extern z80_bit remote_protocol_enabled;
extern int remote_protocol_port;

extern z80_bit hardware_debug_port;

extern char zesarux_zxi_hardware_debug_file[];
extern z80_bit setting_mostrar_visualmem_grafico;


extern z80_bit autosave_snapshot_on_exit;
extern z80_bit autoload_snapshot_on_start;
extern char autosave_snapshot_path_buffer[];

extern z80_bit fast_autoload;

extern z80_bit setting_mostrar_ay_piano_grafico;

extern int kempston_mouse_factor_sensibilidad;

extern int adventure_keyboard_key_length;

extern int adventure_keyboard_send_final_spc;

extern z80_bit use_scrcursesw;

extern z80_bit tbblue_autoconfigure_sd_asked;

extern int menu_allow_background_windows;

extern z80_bit tbblue_store_scanlines;

extern z80_bit tbblue_store_scanlines_border;

extern z80_bit menu_reopen_background_windows_on_start;

extern z80_bit vdp_9918a_unlimited_sprites_line;

extern z80_bit msx_loading_stripes;

extern z80_bit msx_loading_noise_reduction;

extern z80_bit setting_machine_selection_by_name;

#endif

