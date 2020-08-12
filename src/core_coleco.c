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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <time.h>
#include <sys/time.h>
#include <errno.h>


#include "cpu.h"
#include "debug.h"
#include "tape.h"
#include "audio.h"
#include "screen.h"
#include "ay38912.h"
#include "operaciones.h"
#include "snap.h"
#include "timer.h"
#include "menu.h"
#include "compileoptions.h"
#include "contend.h"
#include "ula.h"
#include "utils.h"
#include "realjoystick.h"
#include "chardetect.h"


#include "scrstdout.h"
#include "settings.h"


#include "snap_zsf.h"
#include "zeng.h"
#include "coleco.h"
#include "vdp_9918a.h"
#include "sn76489an.h"


z80_byte byte_leido_core_coleco;


int duracion_ultimo_opcode_coleco=0;









void t_scanline_next_fullborder_coleco(void)
{
        //resetear buffer border

        //int i;



        //a 255
        //for (i=0;i<CURRENT_FULLBORDER_ARRAY_LENGTH;i++) fullbuffer_border[i]=255;
		//mas rapido con memset
		memset(fullbuffer_border,255,CURRENT_FULLBORDER_ARRAY_LENGTH);


	//printf ("max buffer border : %d\n",i);

}

extern z80_byte pref237_opcode_leido;
void interrupcion_si_despues_lda_ir_coleco(void)
{



	//NMOS
	//printf ("leido %d en interrupt\n",byte_leido_core_coleco);
	if (byte_leido_core_coleco==237) {
		//printf ("leido 237 en interrupt, siguiente=%d\n",pref237_opcode_leido);
		if (pref237_opcode_leido==87 || pref237_opcode_leido==95) {
			//printf ("Poner PV a 0 despues de LD a,i o LD a,r\n");
			Z80_FLAGS &=(255-FLAG_PV);
		}
	}
}









void core_coleco_fin_frame_pantalla(void)
{
	//Siguiente frame de pantalla
				core_cpu_timer_frame_difftime=timer_stats_diference_time(&core_cpu_timer_frame_antes,&core_cpu_timer_frame_despues);

				//printf ("tiempo transcurrido: %ld microsec\n",tiempo_timer_difftime);
				//media de tiempo
				core_cpu_timer_frame_media=(core_cpu_timer_frame_media+core_cpu_timer_frame_difftime)/2;
				//printf ("tiempo medio transcurrido: %ld microsec\n",core_cpu_timer_frame_media);




				//tsconf_last_frame_y=-1;

				if (rainbow_enabled.v==1) t_scanline_next_fullborder_coleco();

		        t_scanline=0;

		      
					set_t_scanline_draw_zero();

		     


                                //Parche para maquinas que no generan 312 lineas, porque si enviamos menos sonido se escuchara un click al final
                                //Es necesario que cada frame de pantalla contenga 312 bytes de sonido
                                //Igualmente en la rutina de envio_audio se vuelve a comprobar que todo el sonido a enviar
                                //este completo; esto es necesario para Z88


                int linea_estados=t_estados/screen_testados_linea;

                while (linea_estados<312) {
					audio_send_stereo_sample(audio_valor_enviar_sonido_izquierdo,audio_valor_enviar_sonido_derecho);
					//audio_send_mono_sample(audio_valor_enviar_sonido_izquierdo);
                                        linea_estados++;
                }




                t_estados -=screen_testados_total;

				//Para paperboy, thelosttapesofalbion0 y otros que hacen letras en el border, para que no se desplacen en diagonal
				//t_estados=0;
				//->paperboy queda fijo. thelosttapesofalbion0 no se desplaza, sino que tiembla si no forzamos esto

				audio_tone_generator_last=-audio_tone_generator_last;


				//Final de instrucciones ejecutadas en un frame de pantalla
				if (iff1.v==1) {
					interrupcion_maskable_generada.v=1;


			


					//Si la anterior instruccion ha tardado 32 ciclos o mas
					if (duracion_ultimo_opcode_coleco>=cpu_duracion_pulso_interrupcion) {
						debug_printf (VERBOSE_PARANOID,"Losing last interrupt because last opcode lasts 32 t-states or more");
						interrupcion_maskable_generada.v=0;
					}
				 	




				}

				//Si se genera nmi mediante bit 5 de registro vdp 1
				//VR1
				//5    IE0        V-Blank Interrupt Enable   (0=Disable, 1=Enable)
				if (vdp_9918a_registers[1] & 32) {
					//printf ("Generando nmi\n");
					generate_nmi();

					//Avisar vsync en vdp
					vdp_9918a_status_register |=128;
				}
						


				cpu_loop_refresca_pantalla();

				vofile_send_frame(rainbow_buffer);


				siguiente_frame_pantalla();


				if (debug_registers) scr_debug_registers();

	  	                contador_parpadeo--;
                        	//printf ("Parpadeo: %d estado: %d\n",contador_parpadeo,estado_parpadeo.v);
	                        if (!contador_parpadeo) {
        	                        contador_parpadeo=16;
                	                estado_parpadeo.v ^=1;
	                        }


				if (!interrupcion_timer_generada.v) {
					//Llegado a final de frame pero aun no ha llegado interrupcion de timer. Esperemos...
					//printf ("no demasiado\n");
					esperando_tiempo_final_t_estados.v=1;
				}

				else {
					//Llegado a final de frame y ya ha llegado interrupcion de timer. No esperamos.... Hemos tardado demasiado
					//printf ("demasiado\n");
					esperando_tiempo_final_t_estados.v=0;
				}


				core_end_frame_check_zrcp_zeng_snap.v=1;


}

void core_coleco_fin_scanline(void)
{
//printf ("%d\n",t_estados);
			//if (t_estados>69000) printf ("t_scanline casi final: %d\n",t_scanline);

			if (1) {

				//audio_valor_enviar_sonido=0;

				audio_valor_enviar_sonido_izquierdo=audio_valor_enviar_sonido_derecho=0;

				//audio_valor_enviar_sonido_izquierdo +=da_output_sn_izquierdo();
				//audio_valor_enviar_sonido_derecho +=da_output_sn_derecho();
				audio_valor_enviar_sonido_izquierdo +=da_output_sn();
				audio_valor_enviar_sonido_derecho +=da_output_sn();				


				/*
				if (beeper_enabled.v) {
					if (beeper_real_enabled==0) {
						audio_valor_enviar_sonido_izquierdo += da_amplitud_speaker_coleco();
						audio_valor_enviar_sonido_derecho += da_amplitud_speaker_coleco();
					}

					else {
						char suma_beeper=get_value_beeper_sum_array();
						audio_valor_enviar_sonido_izquierdo += suma_beeper;
						audio_valor_enviar_sonido_derecho += suma_beeper;
						beeper_new_line();
					}

					
				}
				*/

			

				if (realtape_inserted.v && realtape_playing.v) {
					realtape_get_byte();
					if (realtape_loading_sound.v) {
                        audio_valor_enviar_sonido_izquierdo /=2;
	                    audio_valor_enviar_sonido_izquierdo += realtape_last_value/2;

						audio_valor_enviar_sonido_derecho /=2;
	                    audio_valor_enviar_sonido_derecho += realtape_last_value/2;

						//Sonido alterado cuando top speed
						if (timer_condicion_top_speed() ) {
							audio_valor_enviar_sonido_izquierdo=audio_change_top_speed_sound(audio_valor_enviar_sonido_izquierdo);
							audio_valor_enviar_sonido_derecho=audio_change_top_speed_sound(audio_valor_enviar_sonido_derecho);
						}
					}
				}

				//Ajustar volumen
				if (audiovolume!=100) {
					audio_valor_enviar_sonido_izquierdo=audio_adjust_volume(audio_valor_enviar_sonido_izquierdo);
					audio_valor_enviar_sonido_derecho=audio_adjust_volume(audio_valor_enviar_sonido_derecho);
				}

				
				if (audio_tone_generator) {
					audio_send_mono_sample(audio_tone_generator_get() );
				}

				else {
					audio_send_stereo_sample(audio_valor_enviar_sonido_izquierdo,audio_valor_enviar_sonido_derecho);
				}



				sn_chip_siguiente_ciclo();

			

			}

			//final de linea

			//copiamos contenido linea y border a buffer rainbow
			if (rainbow_enabled.v==1) {
				if (!screen_if_refresh()) {
					//if ((t_estados/screen_testados_linea)>319) printf ("-Not storing rainbow buffer as framescreen_saltar is %d or manual frameskip\n",framescreen_saltar);
				}

				else {
					//if ((t_estados/screen_testados_linea)>319) printf ("storing rainbow buffer\n");
					//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_core_coleco_store_scanline_rainbow);
					//screen_store_scanline_rainbow_solo_border();
					//screen_store_scanline_rainbow_solo_display();

					screen_store_scanline_rainbow_coleco_border_and_display();
					//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_core_coleco_store_scanline_rainbow);
				}

				//t_scanline_next_border();

			}

			//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_core_coleco_t_scanline_next_line);
			t_scanline_next_line();
			//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_core_coleco_t_scanline_next_line);


			//se supone que hemos ejecutado todas las instrucciones posibles de toda la pantalla. refrescar pantalla y
			//esperar para ver si se ha generado una interrupcion 1/50

            if (t_estados>=screen_testados_total) {
				//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_core_coleco_fin_frame_pantalla);
				core_coleco_fin_frame_pantalla();
				//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_core_coleco_fin_frame_pantalla);
			} 
			//Fin bloque final de pantalla



}

void core_coleco_handle_interrupts(void)
{
		debug_fired_interrupt=1;

			//printf ("Generada interrupcion Z80\n");

			

			//if (interrupcion_non_maskable_generada.v) printf ("generada nmi\n");

                        //ver si esta en HALT
                        if (z80_ejecutando_halt.v) {
                                        z80_ejecutando_halt.v=0;
                                        reg_pc++;
                        }

					

			if (1==1) {

					if (interrupcion_non_maskable_generada.v) {
						debug_anota_retorno_step_nmi();
						//printf ("generada nmi\n");
                                                interrupcion_non_maskable_generada.v=0;


                                                //NMI wait 14 estados
                                                t_estados += 14;


                                                

												push_valor(reg_pc,PUSH_VALUE_TYPE_NON_MASKABLE_INTERRUPT);


                                                reg_r++;
                                                iff1.v=0;
                                                //printf ("Calling NMI with pc=0x%x\n",reg_pc);

                                                //Otros 6 estados
                                                t_estados += 6;

                                                //Total NMI: NMI WAIT 14 estados + NMI CALL 12 estados
                                                reg_pc= 0x66;

												//printf ("generada nmi pc=%04XH\n",reg_pc);

                                                //temp

                                                t_estados -=15;

											

					

						generate_nmi_prepare_fetch();


					}

					if (1==1) {
					

			


					//justo despues de EI no debe generar interrupcion
					//e interrupcion nmi tiene prioridad
						if (interrupcion_maskable_generada.v && byte_leido_core_coleco!=251) {

						//printf ("Lanzada interrupcion spectrum normal\n");

						debug_anota_retorno_step_maskable();
						//Tratar interrupciones maskable
						interrupcion_maskable_generada.v=0;

						interrupcion_si_despues_lda_ir_coleco();

						

						
						push_valor(reg_pc,PUSH_VALUE_TYPE_MASKABLE_INTERRUPT);

						reg_r++;

						



						//desactivar interrupciones al generar una
						iff1.v=iff2.v=0;
						//Modelos spectrum

						if (im_mode==0 || im_mode==1) {
							cpu_common_jump_im01();
						}
						else {
						//IM 2.

							z80_int temp_i;
							z80_byte dir_l,dir_h;

							

                            temp_i=reg_i*256+255;
							dir_l=peek_byte(temp_i++);
							dir_h=peek_byte(temp_i);
							reg_pc=value_8_to_16(dir_h,dir_l);
							t_estados += 7;

							//Para mejorar demos ula128 y scroll2017
							//Pero esto hace empeorar la demo ulatest3.tap
							if (ula_im2_slow.v) t_estados++;
						}

					}
				}


			}
}




void core_coleco_ciclo_fetch(void)
{

	//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_core_coleco_store_rainbow_current_atributes);
	//core_coleco_store_rainbow_current_atributes();
	//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_core_coleco_store_rainbow_current_atributes);



#ifdef DEBUG_SECOND_TRAP_STDOUT

        //Para poder debugar rutina que imprima texto. Util para aventuras conversacionales
        //hay que definir este DEBUG_SECOND_TRAP_STDOUT manualmente en compileoptions.h despues de ejecutar el configure

	scr_stdout_debug_print_char_routine();

#endif

				

				if (nmi_pending_pre_opcode) {
						//Dado que esto se activa despues de lanzar nmi y antes de leer opcode, aqui saltara cuando PC=66H
						debug_printf (VERBOSE_DEBUG,"Handling nmi mapping pre opcode fetch at %04XH",reg_pc);
						nmi_handle_pending_prepost_fetch();
				}				


				int t_estados_antes_opcode=t_estados;
				core_refetch=0;

				

        	                        contend_read( reg_pc, 4 );
					byte_leido_core_coleco=fetch_opcode();




#ifdef EMULATE_CPU_STATS
				util_stats_increment_counter(stats_codsinpr,byte_leido_core_coleco);
#endif

                reg_pc++;

				//Nota: agregar estos dos if de nmi_pending_pre_opcode y nmi_pending_post_opcode 
				//supone un 0.2 % de uso mas en mi iMac: pasa de usar 5.4% cpu a 5.6% cpu en --vo null y --ao null
				//Es muy poco...
				if (nmi_pending_post_opcode) {
					//Dado que esto se activa despues de lanzar nmi y leer opcode, aqui saltara cuando PC=67H
					debug_printf (VERBOSE_DEBUG,"Handling nmi mapping post opcode fetch at %04XH",reg_pc);
					nmi_handle_pending_prepost_fetch(); 
				}				

				reg_r++;

				


#ifdef EMULATE_SCF_CCF_UNDOC_FLAGS	
				//Guardar antes F
				scf_ccf_undoc_flags_before=Z80_FLAGS;
#endif

	            codsinpr[byte_leido_core_coleco]  () ;


#ifdef EMULATE_SCF_CCF_UNDOC_FLAGS	
				//Para saber si se ha modificado
				scf_ccf_undoc_flags_after_changed=(Z80_FLAGS  == scf_ccf_undoc_flags_before ? 0 : 1);
#endif				

				//Ultima duracion, si es que ultimo opcode no genera fetch de nuevo del opcode
				if (!core_refetch) duracion_ultimo_opcode_coleco=t_estados-t_estados_antes_opcode;
				else duracion_ultimo_opcode_coleco +=t_estados-t_estados_antes_opcode;
						
					

				


			


				

}

//bucle principal de ejecucion de la cpu de spectrum
void cpu_core_loop_coleco(void)
{

		debug_get_t_stados_parcial_pre();

		timer_check_interrupt();



//#ifdef COMPILE_STDOUT
//		if (screen_stdout_driver) scr_stdout_printchar();
//#endif
//
//#ifdef COMPILE_SIMPLETEXT
//                if (screen_simpletext_driver) scr_simpletext_printchar();
//#endif


		if (chardetect_detect_char_enabled.v) chardetect_detect_char();
		if (chardetect_printchar_enabled.v) chardetect_printchar();
	


		//Gestionar autoload. TODO
		//gestionar_autoload_coleco();

		if (0) {}

			/*
		if (tap_load_detect()) {
			//si estamos en pausa, no hacer nada
			if (!tape_pause) {
				audio_playing.v=0;

				draw_tape_text();

				tap_load();
				all_interlace_scr_refresca_pantalla();

				//audio_playing.v=1;
				timer_reset();
			}

			else {
				core_coleco_store_rainbow_current_atributes();
				//generamos nada. como si fuera un NOP
				contend_read( reg_pc, 4 );

			}
		}

		else if (tap_save_detect()) {
			audio_playing.v=0;

			draw_tape_text();

			tap_save();
			//audio_playing.v=1;
			timer_reset();
		}

		*/

		else {
			if (esperando_tiempo_final_t_estados.v==0) {
				//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_core_coleco_ciclo_fetch);
				core_coleco_ciclo_fetch();
				//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_core_coleco_ciclo_fetch);
            }

        }



		


		//A final de cada scanline 
		if ( (t_estados/screen_testados_linea)>t_scanline  ) {
			//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_core_coleco_fin_scanline);
			core_coleco_fin_scanline();			
			//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_core_coleco_fin_scanline);
		}
		

		//Ya hemos leido duracion ultimo opcode. Resetearla a 0 si no hay que hacer refetch
		if (!core_refetch) duracion_ultimo_opcode_coleco=0;		



		if (esperando_tiempo_final_t_estados.v) {
			timer_pause_waiting_end_frame();
		}



		//Interrupcion de 1/50s. mapa teclas activas y joystick
        if (interrupcion_fifty_generada.v) {
			interrupcion_fifty_generada.v=0;

            //y de momento actualizamos tablas de teclado segun tecla leida
			//printf ("Actualizamos tablas teclado %d ", temp_veces_actualiza_teclas++);
			//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_scr_actualiza_tablas_teclado);
			scr_actualiza_tablas_teclado();
			//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_scr_actualiza_tablas_teclado);


			//lectura de joystick
			//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_realjoystick_main);
			realjoystick_main();
			//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_realjoystick_main);



		}


		//Interrupcion de procesador y marca final de frame
		if (interrupcion_timer_generada.v) {
			//printf ("Generada interrupcion timer\n");
			interrupcion_timer_generada.v=0;
			esperando_tiempo_final_t_estados.v=0;
			interlaced_numero_frame++;
			//printf ("%d\n",interlaced_numero_frame);

			//Para calcular lo que se tarda en ejecutar todo un frame
			timer_stats_current_time(&core_cpu_timer_frame_antes);


        }


		//Interrupcion de cpu. gestion im0/1/2. Esto se hace al final de cada frame en spectrum o al cambio de bit6 de R en zx80/81
		if (interrupcion_maskable_generada.v || interrupcion_non_maskable_generada.v) {
			//TIMESENSOR_ENTRY_PRE(TIMESENSOR_ID_core_coleco_handle_interrupts);
			core_coleco_handle_interrupts();
			//TIMESENSOR_ENTRY_POST(TIMESENSOR_ID_core_coleco_handle_interrupts);
        }
		//Fin gestion interrupciones


		//Aplicar snapshot pendiente de ZRCP y ZENG envio snapshots. Despues de haber gestionado interrupciones
		if (core_end_frame_check_zrcp_zeng_snap.v) {
			core_end_frame_check_zrcp_zeng_snap.v=0;
			check_pending_zrcp_put_snapshot();
			zeng_send_snapshot_if_needed();			
		}



		debug_get_t_stados_parcial_post();

}
