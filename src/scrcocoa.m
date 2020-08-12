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


//extraido de: http://yak.net/repos/extern/qemu-kvm-0.14.0/ui/cocoa.m.txt

/*
    This code is based on QEMU Cocoa CG display driver
*/


/*
 * QEMU Cocoa CG display driver
 *
 * Copyright (c) 2008 Mike Kronenberg
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
#include <string.h>
#include <stdio.h>


#include "compileoptions.h"
#include "cpu.h"
#include "screen.h"
#include "charset.h"
#include "debug.h"
#include "utils.h"

#include "timer.h"
#include "menu.h"

#include "joystick.h"
#include "cpc.h"
#include "prism.h"
#include "sam.h"
#include "ql.h"
#include "msx.h"
#include "coleco.h"
#include "sg1000.h"
#include "svi.h"


int gArgc;
char **gArgv;



//Silenciar avisos de OpenGL tipo: scrcocoa.m:638:3: warning: 'glEnable' is deprecated: first deprecated in macOS 10.14 - OpenGL API deprecated. (Define GL_SILENCE_DEPRECATION to silence these warnings) [-Wdeprecated-declarations]
//En algun momento del futuro tocará migrar a Metal...
#define GL_SILENCE_DEPRECATION  

#import <Cocoa/Cocoa.h>

#import <OpenGL/gl.h>



#ifndef MAC_OS_X_VERSION_10_4
#define MAC_OS_X_VERSION_10_4 1040
#endif
#ifndef MAC_OS_X_VERSION_10_5
#define MAC_OS_X_VERSION_10_5 1050
#endif





//caps lock en mac no envia keyup y keydown
//hacemos que cuando se envia evento de caps, activar caps durante un rato
//pasado ese rato, desactivar caps
int cocoa_enviar_caps_contador=0;

//temp
void kbd_mouse_event (int a,int b,int c,int d)
{
}

//temp
void kbd_put_keycode(int a)
{
}

//temp
int is_graphic_console(void)
{
return 1;
}

//temp
void kbd_put_keysym(int a)
{
}

//temp
int kbd_mouse_is_absolute(void)
{
	return 0;
}

#define cgrect(nsrect) (*(CGRect *)&(nsrect))
#define COCOA_MOUSE_EVENT \
        if (isTabletEnabled) { \
            kbd_mouse_event((int)(p.x * 0x7FFF / (screen.width - 1)), (int)((screen.height - p.y) * 0x7FFF / (screen.height - 1)), 0, buttons); \
        } else if (isMouseGrabed) { \
            kbd_mouse_event((int)[event deltaX], (int)[event deltaY], 0, buttons); \
        } else { \
            [NSApp sendEvent:event]; \
        }

typedef struct {
    int width;
    int height;
    int bitsPerComponent;
    int bitsPerPixel;
} QEMUScreen;

id cocoaView;
//static DisplayChangeListener *dcl;


//donde se guarda nuestro bitmap
UInt8 *pixel_screen_data;

//el ancho y alto de nuestro bitmap
NSInteger pixel_screen_width;
NSInteger pixel_screen_height;


// keymap conversion


//estos valores son arbitrarios, solo son para meterlos en el array y luego leerlos, deben ser >255 y no repetirse
#define COCOA_KEY_RETURN 256
#define COCOA_KEY_TAB 257
#define COCOA_KEY_BACKSPACE 258
#define COCOA_KEY_ESCAPE 259
#define COCOA_KEY_RMETA 260
#define COCOA_KEY_LMETA 261
#define COCOA_KEY_LSHIFT 262
#define COCOA_KEY_CAPSLOCK 263
#define COCOA_KEY_LALT 264
#define COCOA_KEY_LCTRL 265
#define COCOA_KEY_RSHIFT 266
#define COCOA_KEY_RALT 267
#define COCOA_KEY_RCTRL 268
#define COCOA_KEY_KP_MULTIPLY 269
#define COCOA_KEY_KP_PLUS 270
#define COCOA_KEY_NUMLOCK 271
#define COCOA_KEY_KP_DIVIDE 272
#define COCOA_KEY_KP_ENTER 273
#define COCOA_KEY_KP_MINUS 274
#define COCOA_KEY_KP_EQUALS 275
#define COCOA_KEY_KP0 276
#define COCOA_KEY_KP1 277
#define COCOA_KEY_KP2 278
#define COCOA_KEY_KP3 279
#define COCOA_KEY_KP4 280
#define COCOA_KEY_KP5 281
#define COCOA_KEY_KP6 282
#define COCOA_KEY_KP7 283
#define COCOA_KEY_KP8 284
#define COCOA_KEY_KP9 285
#define COCOA_KEY_F5 286
#define COCOA_KEY_F6 287
#define COCOA_KEY_F7 288
#define COCOA_KEY_F3 289
#define COCOA_KEY_F8 290
#define COCOA_KEY_F9 291
#define COCOA_KEY_F11 292
#define COCOA_KEY_PRINT 293
#define COCOA_KEY_SCROLLOCK 294
#define COCOA_KEY_F10 295
#define COCOA_KEY_F12 296
#define COCOA_KEY_PAUSE 297
#define COCOA_KEY_INSERT 298
#define COCOA_KEY_HOME 299
#define COCOA_KEY_PAGEUP 300
#define COCOA_KEY_DELETE 301
#define COCOA_KEY_F4 302
#define COCOA_KEY_END 303
#define COCOA_KEY_F2 304
#define COCOA_KEY_PAGEDOWN 305
#define COCOA_KEY_F1 306
#define COCOA_KEY_LEFT 307
#define COCOA_KEY_RIGHT 308
#define COCOA_KEY_DOWN 309
#define COCOA_KEY_UP 310

//Este second backslash es la tecla a la izquierda del 1
//veo que el backslash "normal" aparece con otro numero... este second lo he descubierto yo
#define COCOA_SECOND_BACKSLASH 311

#define COCOA_KEY_KP_COMMA 312

#define COCOA_KEY_F13 313
#define COCOA_KEY_F14 314
#define COCOA_KEY_F15 315

int keymap[] =
{
    'a',    //0
    's',
    'd',
    'f',
    'h',
    'g',
    'z',
    'x',
    'c',
    'v',
    COCOA_SECOND_BACKSLASH,  //10
    'b',
    'q',
    'w',
    'e',
    'r',
    'y',
    't',
    '1',  //18
    '2',
    '3',  //20
    '4',  //21
    '6',
    '5',
    '=',  //24
    '9',
    '7',
    '-',  //27
    '8',
    '0',
    ']',  //30
    'o',
    'u',
    '[',  //33
    'i',
    'p',
    COCOA_KEY_RETURN,
    'l',
    'j',
    '\'',
    'k',  //40
    ';',
    '\\',
    ',',  //43
    '/',
    'n',
    'm',
    '.',  //47
    COCOA_KEY_TAB,
    ' ',
    '`',  //50
    COCOA_KEY_BACKSPACE,
    0,
    COCOA_KEY_ESCAPE,
COCOA_KEY_RMETA,
COCOA_KEY_LMETA,
COCOA_KEY_LSHIFT,
COCOA_KEY_CAPSLOCK,
COCOA_KEY_LALT,
COCOA_KEY_LCTRL,
COCOA_KEY_RSHIFT, //60
COCOA_KEY_RALT,
COCOA_KEY_RCTRL,
0,
0,
COCOA_KEY_KP_COMMA,
0,
COCOA_KEY_KP_MULTIPLY,
0,
COCOA_KEY_KP_PLUS,
0, //70
COCOA_KEY_NUMLOCK,
0,
0,
0,
COCOA_KEY_KP_DIVIDE,
COCOA_KEY_KP_ENTER,
0,
COCOA_KEY_KP_MINUS,
0,
0,  //80
COCOA_KEY_KP_EQUALS,
COCOA_KEY_KP0,
COCOA_KEY_KP1,
COCOA_KEY_KP2,
COCOA_KEY_KP3,
COCOA_KEY_KP4,
COCOA_KEY_KP5,
COCOA_KEY_KP6,
COCOA_KEY_KP7,
0,  //90
COCOA_KEY_KP8,  //91
COCOA_KEY_KP9,  //93
0,
0,
0,
COCOA_KEY_F5,
COCOA_KEY_F6,
COCOA_KEY_F7,
COCOA_KEY_F3,
COCOA_KEY_F8,  //100
COCOA_KEY_F9,
0,
COCOA_KEY_F11,
0,
COCOA_KEY_F13, //COCOA_KEY_PRINT,
0,
COCOA_KEY_F14, //COCOA_KEY_SCROLLOCK,
0,
COCOA_KEY_F10,
0, //110
COCOA_KEY_F12,
0,
COCOA_KEY_F15, //COCOA_KEY_PAUSE,
COCOA_KEY_INSERT,
COCOA_KEY_HOME,
COCOA_KEY_PAGEUP,
COCOA_KEY_DELETE,
COCOA_KEY_F4,
COCOA_KEY_END,
COCOA_KEY_F2, //120
COCOA_KEY_PAGEDOWN,
COCOA_KEY_F1,
COCOA_KEY_LEFT,
COCOA_KEY_RIGHT,
COCOA_KEY_DOWN,
COCOA_KEY_UP




/* completed according to http://www.libsdl.org/cgi/cvsweb.cgi/SDL12/src/video/quartz/SDL_QuartzKeys.h?rev=1.6&content-type=text/x-cvsweb-markup */

/* Aditional 104 Key XP-Keyboard Scancodes from http://www.computer-engineering.org/ps2keyboard/scancodes1.html */
/*
    219 //          0xdb            e0,5b   L GUI
    220 //          0xdc            e0,5c   R GUI
    221 //          0xdd            e0,5d   APPS
        //              E0,2A,E0,37         PRNT SCRN
        //              E1,1D,45,E1,9D,C5   PAUSE
    83  //          0x53    0x53            KP .
// ACPI Scan Codes
    222 //          0xde            E0, 5E  Power
    223 //          0xdf            E0, 5F  Sleep
    227 //          0xe3            E0, 63  Wake
// Windows Multimedia Scan Codes
    153 //          0x99            E0, 19  Next Track
    144 //          0x90            E0, 10  Previous Track
    164 //          0xa4            E0, 24  Stop
    162 //          0xa2            E0, 22  Play/Pause
    160 //          0xa0            E0, 20  Mute
    176 //          0xb0            E0, 30  Volume Up
    174 //          0xae            E0, 2E  Volume Down
    237 //          0xed            E0, 6D  Media Select
    236 //          0xec            E0, 6C  E-Mail
    161 //          0xa1            E0, 21  Calculator
    235 //          0xeb            E0, 6B  My Computer
    229 //          0xe5            E0, 65  WWW Search
    178 //          0xb2            E0, 32  WWW Home
    234 //          0xea            E0, 6A  WWW Back
    233 //          0xe9            E0, 69  WWW Forward
    232 //          0xe8            E0, 68  WWW Stop
    231 //          0xe7            E0, 67  WWW Refresh
    230 //          0xe6            E0, 66  WWW Favorites
*/
};


/*
 ------------------------------------------------------
    ZesaruxCocoaWindow
 ------------------------------------------------------
*/
@interface ZesaruxCocoaWindow : NSWindow
{
}
- (void)activaSelectores;
- (void)redimensionaVentana:(int)width height:(int)height;
- (void)windowWillStartLiveResize:(NSNotification *)notification;
- (void)windowDidEndLiveResize:(NSNotification *)notification;
@end

//NSWindow *normalWindow;
ZesaruxCocoaWindow *normalWindow;

int pendingresize=0;
int pendingresize_w,pendingresize_h;

int pendiente_z88_draw_lower=0;

/*
 ------------------------------------------------------
    ZesaruxCocoaView
 ------------------------------------------------------
*/


@interface ZesaruxCocoaView : NSOpenGLView



{
    QEMUScreen screen;
    NSWindow *fullScreenWindow;
    float cx,cy,cw,ch,cdx,cdy;
    CGDataProviderRef dataProviderRef;
    int modifiers_state[256];
    BOOL isMouseGrabed;
    //BOOL isFullscreen;
    BOOL isAbsoluteEnabled;
    BOOL isTabletEnabled;
    uint texId;
}

//- (void) resizeContentToWidth:(int)w height:(int)h displayState:(DisplayState *)ds;
- (void) resizeContentToWidth:(int)w height:(int)h ;
- (void) setSizeScreen:(int)w height:(int)h ;
- (void) grabMouse;
- (void) ungrabMouse;
- (void) toggleFullScreen:(id)sender;
- (void) migestionEvento:(NSEvent *)event;
- (void) gestionTecla: (NSEvent *)event : (int)pressrelease;
- (void) setAbsoluteEnabled:(BOOL)tIsAbsoluteEnabled;
- (BOOL) isMouseGrabed;
- (BOOL) isAbsoluteEnabled;
- (float) cdx;
- (float) cdy;
- (QEMUScreen) gscreen;
- (void) setContentDimensions;
@end


@implementation ZesaruxCocoaWindow


- (void)activaSelectores
{

	//printf ("ZesaruxCocoaWindow activaSelectores\n");

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidEndLiveResize:) name:NSWindowDidEndLiveResizeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillStartLiveResize:) name:NSWindowWillStartLiveResizeNotification object:nil];

}



- (void)redimensionaVentana:(int)width height:(int)height
{
	debug_printf (VERBOSE_INFO,"resize Window %d X %d",width,height);

	NSWindow *laventana=normalWindow;


        int zoom_x_calculado,zoom_y_calculado;

        debug_printf (VERBOSE_INFO,"zoom_x %d zoom_y %d width: %d get_window_width: %d height: %d get_window_height: %d",zoom_x,zoom_y,width,screen_get_window_size_width_no_zoom_border_en(),height,screen_get_window_size_height_no_zoom_border_en());


        zoom_x_calculado=width/(screen_get_window_size_width_no_zoom_border_en()+screen_get_ext_desktop_width_no_zoom() );
        zoom_y_calculado=height/screen_get_window_size_height_no_zoom_border_en();


        if (!zoom_x_calculado) zoom_x_calculado=1;
        if (!zoom_y_calculado) zoom_y_calculado=1;

        debug_printf (VERBOSE_INFO,"zoom_x: %d zoom_y: %d zoom_x_calculated: %d zoom_y_calculated: %d",zoom_x,zoom_y,zoom_x_calculado,zoom_y_calculado);

        if (zoom_x_calculado!=zoom_x || zoom_y_calculado!=zoom_y) {
                //resize
                debug_printf (VERBOSE_INFO,"Resizing window");

                zoom_x=zoom_x_calculado;
                zoom_y=zoom_y_calculado;
                set_putpixel_zoom();
        }

        pixel_screen_width = screen_get_window_size_width_zoom_border_en();
        pixel_screen_width += screen_get_ext_desktop_width_zoom();

        pixel_screen_height = screen_get_window_size_height_zoom_border_en();

        NSInteger dataLength = pixel_screen_width * pixel_screen_height * 4;
        pixel_screen_data = (UInt8*)malloc(dataLength * sizeof(UInt8));

        ZesaruxCocoaView *elview;
        elview=[ laventana contentView ];

        NSSize nuevosize;
        nuevosize.width=pixel_screen_width;
        nuevosize.height=pixel_screen_height;

        [elview setSizeScreen:pixel_screen_width height:pixel_screen_height];


        [laventana setContentSize:nuevosize];
        [laventana setContentView:elview];


        [laventana center];

        [elview setContentDimensions];

        [elview setFrame:NSMakeRect(0, 0, pixel_screen_width, pixel_screen_height)];
        [ [ laventana contentView ] resizeContentToWidth:(int)(pixel_screen_width) height:(int)(pixel_screen_height) ];

   //printf ("resize: %d X %d\n",width,height);

}


- (void)windowWillStartLiveResize:(NSNotification *)notification
{

	//Bloqueamos operaciones de putpixel o refresco de pantalla
	pendingresize=1;
	pendingresize_w=0;
	pendingresize_h=0;

	debug_printf(VERBOSE_INFO,"The window is going to be resized");


}

- (void)windowDidEndLiveResize:(NSNotification *)notification
{


	/*if (pendingresize) {
		debug_printf (VERBOSE_INFO,"Another resize window operation is pending");
		return;
	}*/

	debug_printf(VERBOSE_INFO,"The window has been resized");

	NSWindow *laventana=[notification object];

	int width=[ [ laventana contentView ] frame ].size.width;
	int height=[ [ laventana contentView ] frame ].size.height;


	pendingresize=1;
	pendingresize_w=width;
	pendingresize_h=height;


	[normalWindow redimensionaVentana:pendingresize_w height:pendingresize_h];
	pendingresize=0;        


}


@end


@implementation ZesaruxCocoaView



-(void)prepareOpenGL
{
	//printf ("prepareOpenGL\n");

  [super prepareOpenGL];

  [self createTexture];

}


-(void)createTexture
{

	//printf ("createTexture %ld %ld\n",pixel_screen_width, pixel_screen_height);

        NSInteger ancho;
        NSInteger alto;

	ancho=pixel_screen_width;
	alto=pixel_screen_height;

	if (ancho==0 || alto==0) {
		//Primera vez inicializacion
		ancho=400;
		alto=300;
	}



        glEnable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glGenTextures(1, &texId); //Creamos una textura

        glBindTexture(GL_TEXTURE_2D, texId);

        //Configuramos la textura
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        //No copiamos nada lo haremos luego (le pasamos null)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ancho, alto, 0, GL_BGRA, GL_UNSIGNED_BYTE, NULL);
}

- (void)render {


        // CGLLockContext([[self openGLContext] CGLContextObj]);

        [[self openGLContext] makeCurrentContext];


        glViewport(0,0,pixel_screen_width, pixel_screen_height);



        //NO BORRAMOS el fondo porque ya lo dibujamos más abajo

        glBindTexture(GL_TEXTURE_2D, texId);
        //Actualizamos la textura
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixel_screen_width, pixel_screen_height, 0, GL_BGRA, GL_UNSIGNED_BYTE, pixel_screen_data);

        glBegin(GL_QUADS);
        glColor4d(1.0,1.0,1.0,1.0); //Color blanco se multiplica con el color de los pixeles de la textura.

        glTexCoord2d(0,1);
        glVertex2d(-1.0, -1.0);

        glTexCoord2d(1,1);
        glVertex2d(1.0,-1.0);

        glTexCoord2d(1,0);
        glVertex2d(1.0,1.0);

        glTexCoord2d(0,0);
        glVertex2d(-1.0,1.0);
        glEnd();

        [[self openGLContext] flushBuffer];

        glFlush();
        /*
        The documentation for -[NSOpenGLContext flushBuffer] says:

        Discussion

        If the receiver is not a double-buffered context, this call does nothing.
        You can cause your context to be double-buffered by including NSOpenGLPFADoubleBuffer in your pixel format attributes. Alternatively, you can call glFlush() instead of -[NSOpenGLContext flushBuffer] and leave your context single-buffered.
        */


        // CGLUnlockContext([[self openGLContext] CGLContextObj]);
}



- (id)initWithFrame:(NSRect)frameRect
{
    //COCOA_DEBUG("ZesaruxCocoaView: initWithFrame\n");

    self = [super initWithFrame:frameRect];
    if (self) {

        screen.bitsPerComponent = 8;
        screen.bitsPerPixel = 32;
        screen.width = frameRect.size.width;
        screen.height = frameRect.size.height;

    }

//Para drag-drop, ver http://juliuspaintings.co.uk/cgi-bin/paint_css/animatedPaint/072-NSView-drag-and-drop.pl

[self registerForDraggedTypes:
      [NSArray arrayWithObjects:NSTIFFPboardType,NSFilenamesPboardType,nil]];

//[self registerForDraggedTypes: 
  //    [NSArray arrayWithObjects:NSPasteboardTypeTIFF,NSFilenamesPboardType,nil]];

      //[self registerForDraggedTypes([NSFilenamesPboardType]) ];


    return self;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
//printf ("Entrando drag drop\n");
if ((NSDragOperationGeneric & [sender draggingSourceOperationMask])
      == NSDragOperationGeneric) {

      return NSDragOperationGeneric;

   } // end if

   // not a drag we can use
   return NSDragOperationNone;

}

/*
- (void)viewWillStartLiveResize
{
    printf ("viewWillStartLiveResize\n");

		[ super viewWillStartLiveResize ];
}

- (void)viewDidEndLiveResize
{
    printf ("viewDidEndLiveResize\n");

		[ super viewDidEndLiveResize ];
}
*/

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
//printf ("Salido drag drop\n");
}

- (BOOL)prepareForDragOperation:(id )sender {
   return YES;
} // end prepareForDragOperation


- (BOOL)performDragOperation:(id )sender {

//printf ("Ejecutando performDragOperation\n");

   NSPasteboard *zPasteboard = [sender draggingPasteboard];
   // define the images  types we accept
   // NSPasteboardTypeTIFF: (used to be NSTIFFPboardType).
   // NSFilenamesPboardType:An array of NSString filenames
   NSArray *zImageTypesAry = [NSArray arrayWithObjects:NSPasteboardTypeTIFF,
                 NSFilenamesPboardType, nil];

   NSString *zDesiredType =
                [zPasteboard availableTypeFromArray:zImageTypesAry];

    if ([zDesiredType isEqualToString:NSFilenamesPboardType]) {
      // the pasteboard contains a list of file names
      //Take the first one
      NSArray *zFileNamesAry =
             [zPasteboard propertyListForType:@"NSFilenamesPboardType"];
      NSString *zPath = [zFileNamesAry objectAtIndex:0];


//printf ("Path: %s\n",[zPath UTF8String]);
/*
      NSImage *zNewImage = [[NSImage alloc] initWithContentsOfFile:zPath];

      if (zNewImage == nil) {
         NSLog(@"Error: MyNSView performDragOperation zNewImage == nil");
         return NO;
      }// end if


      self.nsImageObj = zNewImage;
      [self setNeedsDisplay:YES];
*/



	strcpy(quickload_file,[zPath UTF8String]);



	menu_abierto=1;
	menu_event_drag_drop.v=1;
      return YES;

   }// end if


   //this cant happen ???
   NSLog(@"Error MyNSView performDragOperation");
   return NO;


} // end performDragOperation


- (void)keyDown:(NSEvent *)event
{
[cocoaView gestionTecla:event:1] ;

}

- (void)keyUp:(NSEvent *)event
{
[cocoaView gestionTecla:event:0] ;
}

- (void)mouseUp:(NSEvent *)event
{
	//mouse_left=0;
	util_set_reset_mouse(UTIL_MOUSE_LEFT_BUTTON,0);
}

- (void)rightMouseUp:(NSEvent *)event
{
  //mouse_right=0;
	util_set_reset_mouse(UTIL_MOUSE_RIGHT_BUTTON,0);
}

- (void)scrollWheel:(NSEvent *)event
{
	debug_printf (VERBOSE_PARANOID,"Scroll wheel scrolled %f horizontally and %f vertically", [event deltaX], [event deltaY]);
        mouse_wheel_horizontal=[event deltaX];
        mouse_wheel_vertical=[event deltaY];
}

- (void)leftrightmouseDown:(int)x y:(int)y
{
        gunstick_x=x;
        gunstick_y=y;

        //0,0 en cocoa esta abajo a la izquierda
        //por tanto, para coordenada y, restamos del tope la coordenada y
        gunstick_x=gunstick_x/zoom_x;
        gunstick_y=screen_get_window_size_height_no_zoom_border_en()-gunstick_y/zoom_y;

        debug_printf (VERBOSE_DEBUG,"Mouse Button press. x=%d y=%d. gunstick: x: %d y: %d", x, y,gunstick_x,gunstick_y);

}

- (void)mouseDown:(NSEvent *)event
{

        NSPoint locationInView = [self convertPoint:[event locationInWindow]
                                       fromView:nil];

        //mouse_left=1;
        util_set_reset_mouse(UTIL_MOUSE_LEFT_BUTTON,1);

        //0,0 en cocoa esta abajo a la izquierda
        int posx=locationInView.x;
        int posy=locationInView.y;

	[self leftrightmouseDown:posx y:posy];

}


- (void)rightMouseDown:(NSEvent *)event
{

        NSPoint locationInView = [self convertPoint:[event locationInWindow]
                fromView:nil];

        //mouse_right=1;
        util_set_reset_mouse(UTIL_MOUSE_RIGHT_BUTTON,1);

        //0,0 en cocoa esta abajo a la izquierda
        int posx=locationInView.x;
        int posy=locationInView.y;

        [self leftrightmouseDown:posx y:posy];

}

int cocoa_raton_oculto=0;

- (void)mouseMoved:(NSEvent *)event
{

        NSPoint locationInView = [self convertPoint:[event locationInWindow]
                                       fromView:nil];

        //0,0 en cocoa esta abajo a la izquierda
        mouse_x=locationInView.x;
        mouse_y=screen_get_window_size_height_zoom_border_en()-locationInView.y;

        kempston_mouse_x=mouse_x/zoom_x;
        kempston_mouse_y=255-mouse_y/zoom_y;

		//si esta dentro de la ventana y hay que ocultar puntero

        if (mouse_pointer_shown.v==0) {
                if (mouse_x>=0 && mouse_y>=0 && mouse_x<=screen_get_window_size_width_zoom_border_en() && mouse_y<=screen_get_window_size_height_zoom_border_en() ) {
                        if (!cocoa_raton_oculto) {
                                debug_printf (VERBOSE_PARANOID,"Mouse inside window and not hidden. Hide it");
                                cocoa_raton_oculto=1;
                                [NSCursor hide];
                        }
                }

                else {
                        if (cocoa_raton_oculto) {
                                debug_printf (VERBOSE_PARANOID,"Mouse outside window and hidden. Unhide it");
                                cocoa_raton_oculto=0;
                                [NSCursor unhide];
                        }
                }

        }

        else {
           //Si se tiene que mostrar, pero se habia ocultado y ahora se ha vuelto a habilitar el setting
           if (cocoa_raton_oculto) {
                debug_printf (VERBOSE_PARANOID,"Mouse was hidden and the setting is now enabled. Unhide it");
		cocoa_raton_oculto=0;
		[NSCursor unhide];                   
           }
        }


        //debug_printf (VERBOSE_PARANOID,"Mouse motion. X: %d Y:%d kempston x: %d y: %d",mouse_x,mouse_y,kempston_mouse_x,kempston_mouse_y);
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

//Cuando se mueve y hay boton pulsado, genera esto
- (void)mouseDragged:(NSEvent *)event
{
        debug_printf (VERBOSE_PARANOID,"Mouse dragged");

        [self mouseDown:event];
        [self mouseMoved:event];
}

//Cuando se mueve y hay boton pulsado, genera esto
- (void)rightMouseDragged:(NSEvent *)event
{
        debug_printf (VERBOSE_PARANOID,"Mouse dragged");

        [self rightMouseDown:event];
        [self mouseMoved:event];
}



- (void) flagsChanged:(NSEvent *)event {
	[cocoaView migestionEvento:event];
}


- (void) dealloc
{
    //COCOA_DEBUG("ZesaruxCocoaView: dealloc\n");

    if (dataProviderRef) CGDataProviderRelease(dataProviderRef);

    [super dealloc];
}

- (BOOL) isOpaque
{
    return YES;
}



- (void) setContentDimensions
{

    if (ventana_fullscreen) {

	//Esto da distorsion de proporcion y llenado total de pantalla (cosa que quiza no queremos)
        /*cdx = [[NSScreen mainScreen] frame].size.width / (float)screen.width;
        cdy = [[NSScreen mainScreen] frame].size.height / (float)screen.height;
        cw = screen.width * cdx;
        ch = screen.height * cdy;
        cx = ([[NSScreen mainScreen] frame].size.width - cw) / 2.0;
        cy = ([[NSScreen mainScreen] frame].size.height - ch) / 2.0;
	*/

	//printf ("[[NSScreen mainScreen] frame].size %f X %f\n",[[NSScreen mainScreen] frame].size.width,[[NSScreen mainScreen] frame].size.height);

	int anchopantalla=[[NSScreen mainScreen] frame].size.width;
	int altopantalla=[[NSScreen mainScreen] frame].size.height;

	//Establecemos alto ventana. Ancho va en proporcion
	int proporcion_y=altopantalla/screen.height;
	int altoventana=screen.height*proporcion_y;
	int anchoventana=screen.width*proporcion_y;

	cdy=proporcion_y;
	cdx=proporcion_y;


        cw = anchoventana;
        ch = altoventana;

	//printf ("ventana: %d X %d proporciones x: %f y: %f\n",anchoventana,altoventana,cdx,cdy);

        cx = (anchopantalla - cw) / 2.0;
        cy = (altopantalla - ch) / 2.0;

        } 
        else {
                cx = 0;
                cy = 0;
                cw = screen.width;
                ch = screen.height;
                cdx = 1.0;
                cdy = 1.0;
        }

}


- (void) setSizeScreen:(int)w height:(int)h
{
	screen.width=w;
	screen.height=h;
}

- (void) resizeContentToWidth:(int)w height:(int)h
{
	debug_printf (VERBOSE_INFO,"resizeContentToWidth %d X %d",w,h);

        int timeout=100;

        if (sem_screen_refresh_reallocate_layers) {
                debug_printf (VERBOSE_DEBUG,"About to run resizeContentToWidth in the middle of a screen refresh. Wait until finish refreshing");
        }

        while (sem_screen_refresh_reallocate_layers && timeout) {
                //printf ("Se va a hacer resizeContentToWidth en medio de refresco. Esperar\n");

                //esto parece que solo sucede al inicio del programa? y solo en Cocoa?
                //este tipo de cosas parece que solo sucede en cocoa pues el driver de video va con un thread aparte a su bola
                //cuando genera error aqui entra por un resize de un evento "automatico" de cocoa
                //esto es independiente de ZX Desktop, ya este habilitado o no, puede suceder esto
                //si no controlase esto, acaba generando segmentation fault (pero parece que el segmentation fault solo cuando esta habilitado ZX Desktop)

                usleep(10000); //0.01 segundo

                timeout--;
        }

        //Si ha saltado el timeout despues de 100 intentos (100*0.01=1 segundo) y sigue reallocating, que pase lo que pase, pero que salga de ahi

        scr_reallocate_layers_menu(w,h);      

        // update screenBuffer
        if (dataProviderRef) CGDataProviderRelease(dataProviderRef);


    //sync host window color space with guests
	screen.bitsPerPixel = 32;
	screen.bitsPerComponent = 4 * 2;

        dataProviderRef = CGDataProviderCreateWithData(NULL, pixel_screen_data, w * 4 * h, NULL);


        // update windows
        if (ventana_fullscreen) {
                [[fullScreenWindow contentView] setFrame:[[NSScreen mainScreen] frame]];

                [normalWindow setFrame:NSMakeRect([normalWindow frame].origin.x, [normalWindow frame].origin.y - h + screen.height, w, h + [normalWindow frame].size.height - screen.height) display:NO animate:NO];
        } else {

                [normalWindow setFrame:NSMakeRect([normalWindow frame].origin.x, [normalWindow frame].origin.y - h + screen.height, w, h + [normalWindow frame].size.height - screen.height) display:YES animate:NO];
        }


        screen.width = w;
        screen.height = h;
        [normalWindow center];
        [self setContentDimensions];

        [self setFrame:NSMakeRect(cx, cy, cw, ch)];

	//printf ("crear ventana de %f X %f \n",cw,ch);
	clear_putpixel_cache();
	modificado_border.v=1;
	//Parece que hay que hacer el screen_z88_draw_lower_screen retardado (en refresca pantalla) no aqui
	//TODO. en el futuro habria que hacer una variable comun (tipo modificado_border) que se lea desde todos los drivers e
	//indique cuando hay que llamar a screen_z88_draw_lower_screen
	pendiente_z88_draw_lower=1;


	[self createTexture];



}


- (void) toggleFullScreen:(id)sender
{
    //COCOA_DEBUG("ZesaruxCocoaView: toggleFullScreen\n");

    if (ventana_fullscreen) { // switch from fullscreen to desktop
        ventana_fullscreen = 0;
        [self ungrabMouse];
        [self setContentDimensions];

// test if host supports "exitFullScreenModeWithOptions" at compile time
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
        if ([NSView respondsToSelector:@selector(exitFullScreenModeWithOptions:)]) { // test if "exitFullScreenModeWithOptions" is supported on host at runtime
            [self exitFullScreenModeWithOptions:nil];
        } else {
#endif
            [fullScreenWindow close];
            [normalWindow setContentView: self];
            [normalWindow makeKeyAndOrderFront: self];
            [NSMenu setMenuBarVisible:YES];

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
        }
#endif

    } else { // switch from desktop to fullscreen
        ventana_fullscreen = 1;
        [self grabMouse];
        [self setContentDimensions];

// test if host supports "enterFullScreenMode:withOptions" at compile time
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
        if ([NSView respondsToSelector:@selector(enterFullScreenMode:withOptions:)]) { // test if "enterFullScreenMode:withOptions" is supported on host at runtime

            [self enterFullScreenMode:[NSScreen mainScreen] withOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool:NO], NSFullScreenModeAllScreens,
                [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kCGDisplayModeIsStretched, nil], NSFullScreenModeSetting, nil]];

		//printf ("full screen desde enterFullScreenMode:[NSScreen mainScreen] withOptions:nil\n");

                //temp [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], nil, nil], NSFullScreenModeSetting, nil]];
        } else {
#endif

		//Ocultar menu, dock
            [NSMenu setMenuBarVisible:NO];


		//TODO fullscreen. Esto llena la pantalla completamente, distorsionando

            fullScreenWindow = [[NSWindow alloc] initWithContentRect:[[NSScreen mainScreen] frame]
                styleMask:NSWindowStyleMaskBorderless
                backing:NSBackingStoreBuffered
                defer:NO];

		//TODO fullscreen. Esto	pone el tamanyo que queremos, pero no oculta el resto de detras, por tanto no aparenta ser pantalla completa

		/*
            fullScreenWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect (0.0, 0.0, 1274.0, 1080.0)
                styleMask:NSBorderlessWindowMask
                backing:NSBackingStoreBuffered
                defer:NO];
		*/

            [fullScreenWindow setHasShadow:NO];
            [fullScreenWindow setContentView:self];
            [fullScreenWindow makeKeyAndOrderFront:self];


	//esto parece que no hace nada [fullScreenWindow setResizeIncrements:NSMakeSize(1.0,1.0)];

		//printf ("full screen desde fullScreenWindow\n");

		//printf ("[[NSScreen mainScreen] frame].size %f X %f\n",[[NSScreen mainScreen] frame].size.width,[[NSScreen mainScreen] frame].size.height);

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
        }
#endif
    }
}




//Teclas de Z88 asociadas a cada tecla del teclado fisico
int scrcocoa_keymap_z88_cpc_minus;
int scrcocoa_keymap_z88_cpc_equal;
int scrcocoa_keymap_z88_cpc_backslash;
int scrcocoa_keymap_z88_cpc_bracket_left;
int scrcocoa_keymap_z88_cpc_bracket_right;
int scrcocoa_keymap_z88_cpc_semicolon;
int scrcocoa_keymap_z88_cpc_apostrophe;
int scrcocoa_keymap_z88_cpc_pound;
int scrcocoa_keymap_z88_cpc_comma;
int scrcocoa_keymap_z88_cpc_period;
int scrcocoa_keymap_z88_cpc_slash;


int scrcocoa_keymap_z88_cpc_circunflejo;
int scrcocoa_keymap_z88_cpc_colon;
int scrcocoa_keymap_z88_cpc_arroba;
int scrcocoa_keymap_z88_cpc_leftz; //Tecla a la izquierda de la Z. Solo usada en Chloe

//- (void) gestionTecla:(NSEvent *)event pressrelease:(int)pressrelease
- (void) gestionTecla: (NSEvent *)event : (int)pressrelease
{
    //COCOA_DEBUG("ZesaruxCocoaView: gestionTecla\n");

	//La tecla cmd tiene la "particular" caracteristica de que al pulsarla, no envia release del resto de teclas
	//por tanto, cuando se esta pulsada, liberar teclas y volver
	/*
	if (scrcocoa_antespulsadocmd==1) {
		//printf ("cmd key pressed. resetting all keys\n");
		reset_keyboard_ports();
		return;
	}
	*/

	//printf ("cmd key: %d\n",scrcocoa_antespulsadocmd);

        int buttons = 0;
        int cocoakeycode;
        NSPoint p = [event locationInWindow];
        cocoakeycode=[event keyCode];
        //printf ("cocoakeycode tecla %d pressrelease: %d\n",cocoakeycode,pressrelease);

	int teclareal=0;
        //printf ("gestionTecla.tecla: %d contador: %d\n",cocoakeycode,temp_cocoa_contador++);

	//printf ("sizeof array: %d\n",sizeof(keymap));
	if (cocoakeycode<sizeof(keymap)/sizeof(int) ) {
		teclareal=keymap[cocoakeycode];
	}

	if (pressrelease) notificar_tecla_interrupcion_si_z88();

        //printf ("teclareal %d pressrelease: %d\n",teclareal,pressrelease);

	//Teclas que necesitan conversion de teclado para Chloe
	int tecla_gestionada_chloe=0;
        if (MACHINE_IS_SPECTRUM && chloe_keyboard.v) {
                tecla_gestionada_chloe=1;

                if (teclareal==scrcocoa_keymap_z88_cpc_minus) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_MINUS,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_equal) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_EQUAL,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_backslash) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_BACKSLASH,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_bracket_left) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_BRACKET_LEFT,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_bracket_right) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_BRACKET_RIGHT,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_semicolon) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_SEMICOLON,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_apostrophe) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_APOSTROPHE,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_pound) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_POUND,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_comma) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_COMMA,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_period) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_PERIOD,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_slash) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_SLASH,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_leftz) util_set_reset_key_chloe_keymap(UTIL_KEY_CHLOE_LEFTZ,pressrelease);

                else tecla_gestionada_chloe=0;
        }


	if (tecla_gestionada_chloe) return;



	int tecla_gestionada_sam_ql=0;
	if (MACHINE_IS_SAM || MACHINE_IS_QL || MACHINE_IS_MSX || MACHINE_IS_SVI) {
		tecla_gestionada_sam_ql=1;

                if (teclareal==scrcocoa_keymap_z88_cpc_minus) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_MINUS,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_equal) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_EQUAL,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_backslash) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_BACKSLASH,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_bracket_left) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_BRACKET_LEFT,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_bracket_right) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_BRACKET_RIGHT,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_semicolon) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_SEMICOLON,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_apostrophe) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_APOSTROPHE,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_pound) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_POUND,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_comma) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_COMMA,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_period) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_PERIOD,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_slash) util_set_reset_key_common_keymap(UTIL_KEY_COMMON_KEYMAP_SLASH,pressrelease);


		else tecla_gestionada_sam_ql=0;
	}

	if (tecla_gestionada_sam_ql) return;





        switch (teclareal) {
                case COCOA_KEY_ESCAPE:
                        util_set_reset_key(UTIL_KEY_ESC,pressrelease);
                break;

                case COCOA_KEY_RETURN:
                        util_set_reset_key(UTIL_KEY_ENTER,pressrelease);
               break;

                case COCOA_KEY_DOWN:
                        util_set_reset_key(UTIL_KEY_DOWN,pressrelease);
                break;

                case COCOA_KEY_UP:
                        util_set_reset_key(UTIL_KEY_UP,pressrelease);
                break;

                case COCOA_KEY_LEFT:
                        util_set_reset_key(UTIL_KEY_LEFT,pressrelease);
                break;

                case COCOA_KEY_RIGHT:
                        util_set_reset_key(UTIL_KEY_RIGHT,pressrelease);
                break;

                case COCOA_KEY_HOME:
                        util_set_reset_key(UTIL_KEY_HOME,pressrelease);
                break;                        


                case ' ':
                        util_set_reset_key(UTIL_KEY_SPACE,pressrelease);
                break;

                // Estos de shift , alt y control no se leen por aqui en teoria
                case COCOA_KEY_LSHIFT:
                        util_set_reset_key(UTIL_KEY_SHIFT_L,pressrelease);
                break;

                case COCOA_KEY_RSHIFT:
                        util_set_reset_key(UTIL_KEY_SHIFT_R,pressrelease);
                break;

                case COCOA_KEY_LALT:
                        util_set_reset_key(UTIL_KEY_ALT_L,pressrelease);
                break;

                case COCOA_KEY_RALT:
                        util_set_reset_key(UTIL_KEY_ALT_R,pressrelease);
                break;

                case COCOA_KEY_LCTRL:
                        util_set_reset_key(UTIL_KEY_CONTROL_L,pressrelease);
                break;

                case COCOA_KEY_RCTRL:
                        util_set_reset_key(UTIL_KEY_CONTROL_R,pressrelease);
                break;


                //Teclas que generan doble pulsacion
                case COCOA_KEY_BACKSPACE:
                        util_set_reset_key(UTIL_KEY_BACKSPACE,pressrelease);
                break;





                /* Estos parece que no existen en mac
                case COCOA_KEY_KP_Left:
                        util_set_reset_key(UTIL_KEY_LEFT,pressrelease);
                break;

                case COCOA_KEY_KP_Right:
                        util_set_reset_key(UTIL_KEY_RIGHT,pressrelease);
                break;


                case COCOA_KEY_KP_Down:
                        util_set_reset_key(UTIL_KEY_DOWN,pressrelease);
                break;

                case COCOA_KEY_KP_Up:
                        util_set_reset_key(UTIL_KEY_UP,pressrelease);
                break;

                */

                case ',':
                        util_set_reset_key(',',pressrelease);
                break;

                case '.':
                        util_set_reset_key('.',pressrelease);
                break;

                case '<':
                util_set_reset_key('<',pressrelease);
                break;

                case '>':
                util_set_reset_key('>',pressrelease);
                break;

                case COCOA_KEY_TAB:
                        util_set_reset_key(UTIL_KEY_TAB,pressrelease);
                break;

                case COCOA_KEY_CAPSLOCK:
                        util_set_reset_key(UTIL_KEY_CAPS_LOCK,pressrelease);
                break;



                case COCOA_KEY_KP_MINUS:
                        util_set_reset_key(UTIL_KEY_MINUS,pressrelease);
                break;

                case COCOA_KEY_KP_PLUS:
                        util_set_reset_key(UTIL_KEY_PLUS,pressrelease);
                break;

                case COCOA_KEY_KP_DIVIDE:
                        util_set_reset_key(UTIL_KEY_SLASH,pressrelease);
                break;

                case COCOA_KEY_KP_MULTIPLY:
                        util_set_reset_key(UTIL_KEY_ASTERISK,pressrelease);
                break;


                //F1 pulsado
                case COCOA_KEY_F1:
                        util_set_reset_key(UTIL_KEY_F1,pressrelease);
                break;

                //F2 pulsado
                case COCOA_KEY_F2:
                        util_set_reset_key(UTIL_KEY_F2,pressrelease);
                break;

                //F3 pulsado
                case COCOA_KEY_F3:
                        util_set_reset_key(UTIL_KEY_F3,pressrelease);
                break;

                //F4 pulsado
                case COCOA_KEY_F4:
                        util_set_reset_key(UTIL_KEY_F4,pressrelease);
                break;

                //F5 pulsado
                case COCOA_KEY_F5:
                        util_set_reset_key(UTIL_KEY_F5,pressrelease);
                break;


                //F6 pulsado
                case COCOA_KEY_F6:
                        util_set_reset_key(UTIL_KEY_F6,pressrelease);
                break;

                //F7 pulsado
                case COCOA_KEY_F7:
                        util_set_reset_key(UTIL_KEY_F7,pressrelease);
                break;


                //F8 pulsado. osdkeyboard
                case COCOA_KEY_F8:
                        util_set_reset_key(UTIL_KEY_F8,pressrelease);
                break;


                //F9 pulsado. smartload
                case COCOA_KEY_F9:
                        util_set_reset_key(UTIL_KEY_F9,pressrelease);
                break;

                //F10 pulsado
                case COCOA_KEY_F10:
                        util_set_reset_key(UTIL_KEY_F10,pressrelease);
                break;

                //F11 pulsado
                case COCOA_KEY_F11:
                        util_set_reset_key(UTIL_KEY_F11,pressrelease);
                break;

                //F12 pulsado
                case COCOA_KEY_F12:
                        util_set_reset_key(UTIL_KEY_F12,pressrelease);
                break;

                //F13 pulsado
                case COCOA_KEY_F13:
                        util_set_reset_key(UTIL_KEY_F13,pressrelease);
                break;

                //F14 pulsado
                case COCOA_KEY_F14:
                        util_set_reset_key(UTIL_KEY_F14,pressrelease);
                break;

                //F15 pulsado
                case COCOA_KEY_F15:
                        util_set_reset_key(UTIL_KEY_F15,pressrelease);
                break;


                //PgUp
                case COCOA_KEY_PAGEUP:
                        util_set_reset_key(UTIL_KEY_PAGE_UP,pressrelease);
                break;


                //PgDn
                case COCOA_KEY_PAGEDOWN:
                        util_set_reset_key(UTIL_KEY_PAGE_DOWN,pressrelease);
                break;


                //Teclas del keypad
                case COCOA_KEY_KP0:
                        util_set_reset_key(UTIL_KEY_KP0,pressrelease);
                break;

                case COCOA_KEY_KP1:
                        util_set_reset_key(UTIL_KEY_KP1,pressrelease);
                break;

                case COCOA_KEY_KP2:
                        util_set_reset_key(UTIL_KEY_KP2,pressrelease);
                break;

                case COCOA_KEY_KP3:
                        util_set_reset_key(UTIL_KEY_KP3,pressrelease);
                break;

                case COCOA_KEY_KP4:
                        util_set_reset_key(UTIL_KEY_KP4,pressrelease);
                break;

                case COCOA_KEY_KP5:
                        util_set_reset_key(UTIL_KEY_KP5,pressrelease);
                break;

                case COCOA_KEY_KP6:
                        util_set_reset_key(UTIL_KEY_KP6,pressrelease);
                break;

                case COCOA_KEY_KP7:
                        util_set_reset_key(UTIL_KEY_KP7,pressrelease);
                break;

                case COCOA_KEY_KP8:
                        util_set_reset_key(UTIL_KEY_KP8,pressrelease);
                break;

                case COCOA_KEY_KP9:
                        util_set_reset_key(UTIL_KEY_KP9,pressrelease);
                break;

                case COCOA_KEY_KP_COMMA:
                        util_set_reset_key(UTIL_KEY_KP_COMMA,pressrelease);
                break;

                case COCOA_KEY_KP_ENTER:
                        util_set_reset_key(UTIL_KEY_KP_ENTER,pressrelease);
                break;



                default:

                        //tecla ordinaria
                        //printf (" parseada: %u '%c' \n",teclareal, ( teclareal>31 && teclareal<128 ? teclareal : '.' ) );

                        if (teclareal<256) {
                                util_set_reset_key(teclareal,pressrelease);
                                //convert_numeros_letras_puerto_teclado(teclareal,pressrelease);
                        }
                break;


        }


//Fuera del switch

	//Teclas que necesitan conversion de teclado para CPC
	if (MACHINE_IS_CPC) {

                if (teclareal==scrcocoa_keymap_z88_cpc_minus) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_MINUS,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_circunflejo) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_CIRCUNFLEJO,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_arroba) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_ARROBA,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_bracket_left) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_BRACKET_LEFT,pressrelease);



                else if (teclareal==scrcocoa_keymap_z88_cpc_colon) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_COLON,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_semicolon) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_SEMICOLON,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_bracket_right) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_BRACKET_RIGHT,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_comma) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_COMMA,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_period) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_PERIOD,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_slash) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_SLASH,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_backslash) util_set_reset_key_cpc_keymap(UTIL_KEY_CPC_BACKSLASH,pressrelease);


	}

   


        //Teclas que necesitan conversion de teclado para Z88
        if (!MACHINE_IS_Z88) return;

                if (teclareal==scrcocoa_keymap_z88_cpc_minus) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_MINUS,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_equal) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_EQUAL,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_backslash) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_BACKSLASH,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_bracket_left) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_BRACKET_LEFT,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_bracket_right) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_BRACKET_RIGHT,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_semicolon) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_SEMICOLON,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_apostrophe) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_APOSTROPHE,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_pound) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_POUND,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_comma) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_COMMA,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_period) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_PERIOD,pressrelease);

                else if (teclareal==scrcocoa_keymap_z88_cpc_slash) util_set_reset_key_z88_keymap(UTIL_KEY_Z88_SLASH,pressrelease);



}

//inicializarlos con valores 0 al principio
int scrcocoa_antespulsadoctrl=0,scrcocoa_antespulsadoalt=0,scrcocoa_antespulsadoshift_l=0,scrcocoa_antespulsadoshift_r=0,scrcocoa_antespulsadocmd=0; //,scrcocoa_antespulsadocapslock=0;

- (void) migestionEvento:(NSEvent *)event
{
        //printf ("\nmigestionEvento\n");


        //asumimos teclas de control no pulsadas
        int pulsadoctrl,pulsadoalt,pulsadoshift_l,pulsadoshift_r,pulsadocmd; //,pulsadocapslock;
        pulsadoctrl=pulsadoalt=pulsadoshift_l=pulsadoshift_r=pulsadocmd=0;

        int event_keycode,event_type,event_modifier_flags;
        NSPoint p = [event locationInWindow];

	event_type=[event type];
	event_keycode=[event keyCode];
	event_modifier_flags=[event modifierFlags];

	//printf ("event_modifier_flags: 0x%X\n",event_modifier_flags);

	//printf ("event type: %d event keycode: %d event_modifier_flags: %d\n",event_type,event_keycode,event_modifier_flags);

	//https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSEvent_Class/#//apple_ref/doc/constant_group/Function_Key_Unicodes

        if (event_keycode==0x39) {
                //printf ("enviar caps lock durante 10/50 s\n");
                cocoa_enviar_caps_contador=10;
                util_set_reset_key(UTIL_KEY_CAPS_LOCK,1);
        }


	/*if (event_modifier_flags & NSAlphaShiftKeyMask) {
		printf ("Caps lock key pressed\n");
		pulsadocapslock=1;
	}
	*/

	if (event_modifier_flags & NSEventModifierFlagShift) {
		//printf ("Shift key is pressed\n");
		//printf ("NSShiftKeyMask: 0x%X\n",NSShiftKeyMask);

		/* Estos valores los he encontrado probando:
		NSShiftKeyMask: 0x20000

		left shift: 0x20002

		right shift: 0x20004

*/

		if ( (event_modifier_flags & 0x20004)==0x20004) {
			//printf ("Right Shift key is pressed\n");
			pulsadoshift_r=1;
		}
		if ( (event_modifier_flags & 0x20002)==0x20002) {
			//printf ("Left Shift key is pressed\n");
			pulsadoshift_l=1;
		}

		//dado que estos valores los he obtenido probando, por si acaso, se ha entrado aqui pero no se cumple ni left ni right, metemos left
		if (pulsadoshift_l==0 && pulsadoshift_r==0) {
			debug_printf (VERBOSE_DEBUG,"Strange behaviour. Shift pressed but do not know if left or right. Asuming left");
			//printf ("Strange behaviour. Shift pressed but do not know if left or right. Asuminng left\n");
			pulsadoshift_l=1;
		}
	}
	if (event_modifier_flags & NSEventModifierFlagControl) {
		//printf ("Control key is pressed\n");
		pulsadoctrl=1;
	}
	if (event_modifier_flags & NSEventModifierFlagOption) {
		//printf ("Alt key is pressed\n");
		pulsadoalt=1;
	}
	if (event_modifier_flags & NSEventModifierFlagCommand) {
		//printf ("Cmd key is pressed\n");
		//Al pulsar cmd no se liberan teclas. liberamos a mano
		pulsadocmd=1;
	}

	//if (pulsadoctrl) printf ("Control key is pressed\n");
	//else printf ("Control key is NOT pressed\n");

	//notificar cambios
	if (pulsadoshift_l!=scrcocoa_antespulsadoshift_l) {
		//printf ("notificar cambio shift left\n");
		util_set_reset_key(UTIL_KEY_SHIFT_L,pulsadoshift_l);
	}

        //notificar cambios
        if (pulsadoshift_r!=scrcocoa_antespulsadoshift_r) {
                //printf ("notificar cambio shift right\n");
                util_set_reset_key(UTIL_KEY_SHIFT_R,pulsadoshift_r);
        }



	if (pulsadoctrl!=scrcocoa_antespulsadoctrl) {
		//printf ("notificar cambio ctrl. ahora: %d\n",pulsadoctrl);
		util_set_reset_key(UTIL_KEY_CONTROL_L,pulsadoctrl);
	}

	if (pulsadoalt!=scrcocoa_antespulsadoalt) {
		//printf ("notificar cambio alt\n");
		util_set_reset_key(UTIL_KEY_ALT_L,pulsadoalt);
	}


	if (pulsadocmd!=scrcocoa_antespulsadocmd) {
		//printf ("notificar cambio cmd. ahora: %d\n",pulsadocmd);
		reset_keyboard_ports();
	        //La tecla cmd tiene la "particular" caracteristica de que al pulsarla, no envia release del resto de teclas
        	//por tanto, cuando se esta pulsada, liberar teclas
		util_set_reset_key(UTIL_KEY_WINKEY,pulsadocmd);
	}



	scrcocoa_antespulsadoctrl=pulsadoctrl;
	scrcocoa_antespulsadoalt=pulsadoalt;
	scrcocoa_antespulsadoshift_l=pulsadoshift_l;
	scrcocoa_antespulsadoshift_r=pulsadoshift_r;
	scrcocoa_antespulsadocmd=pulsadocmd;

	//printf ("\nfin migestionEvento\n\n");

}

- (void) grabMouse
{
    //COCOA_DEBUG("ZesaruxCocoaView: grabMouse\n");
	//printf ("grabMouse\n");

    if (!ventana_fullscreen) {
            [normalWindow setTitle:@"ZEsarUX - (Press ctrl + alt to release Mouse)"];
    }
    [NSCursor hide];
    CGAssociateMouseAndMouseCursorPosition(FALSE);
    isMouseGrabed = TRUE; // while isMouseGrabed = TRUE, ZesaruxCocoaApp sends all events to [cocoaView gestionEvento:]
}

- (void) ungrabMouse
{
    //COCOA_DEBUG("ZesaruxCocoaView: ungrabMouse\n");

    if (!ventana_fullscreen) {
            [normalWindow setTitle:@"ZEsarUX "EMULATOR_VERSION ];
    }
    [NSCursor unhide];
    CGAssociateMouseAndMouseCursorPosition(TRUE);
    isMouseGrabed = FALSE;
}

- (void) setAbsoluteEnabled:(BOOL)tIsAbsoluteEnabled {isAbsoluteEnabled = tIsAbsoluteEnabled;}
- (BOOL) isMouseGrabed {return isMouseGrabed;}
- (BOOL) isAbsoluteEnabled {return isAbsoluteEnabled;}
- (float) cdx {return cdx;}
- (float) cdy {return cdy;}
- (QEMUScreen) gscreen {return screen;}
@end







/*
 ------------------------------------------------------
    ZesaruxCocoaAppController
 ------------------------------------------------------
*/
@interface ZesaruxCocoaAppController : NSObject
{
}
- (void)startEmulationWithArgc:(int)argc argv:(char**)argv;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)toggleFullScreen:(id)sender;
- (void)showQEMUDoc:(id)sender;
- (void)showQEMUTec:(id)sender;
- (void)openzesaruxmenu:(id)sender;
- (void)setzoomone:(id)sender;

@end

@implementation ZesaruxCocoaAppController
- (id) init
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: init\n");

    self = [super init];
    if (self) {

        // create a view and add it to the window
	//tamanyo inicial da un poco igual porque luego se redimensiona al tamanyo real necesario del ordenador emulado
        cocoaView = [[ZesaruxCocoaView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 704.0, 656.0)];
        if(!cocoaView) {
            fprintf(stderr, "(cocoa) can't create a view\n");
            exit(1);
        }

        // create a window
        normalWindow = [[ZesaruxCocoaWindow alloc] initWithContentRect:[cocoaView frame]
            //styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask|NSClosableWindowMask|NSResizableWindowMask
						styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable
            backing:NSBackingStoreBuffered defer:NO];


        if(!normalWindow) {
            fprintf(stderr, "(cocoa) can't create window\n");
            exit(1);
        }
        [normalWindow setAcceptsMouseMovedEvents:YES];
        [normalWindow setTitle:[NSString stringWithFormat:@"ZEsarUX "EMULATOR_VERSION]];
        [normalWindow setContentView:cocoaView];
        //deprecated . mirar alternativa [normalWindow useOptimizedDrawing:YES];
        [normalWindow makeKeyAndOrderFront:self];
		[normalWindow center];


	//[normalWindow setResizeIncrements:NSMakeSize(screen_get_window_size_width_zoom_border_en(), screen_get_window_size_height_zoom_border_en()) ];

	[normalWindow activaSelectores];


/*
[[NSNotificationCenter defaultCenter]
      addObserver:self
      selector:@selector(windowDidEndLiveResize:)
      name:NSWindowDidEndLiveResizeNotification
      object:normalWindow];
*/

    }
    return self;
}

- (void) dealloc
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: dealloc\n");

    if (cocoaView)
        [cocoaView release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching: (NSNotification *) note
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: applicationDidFinishLaunching\n");

[self startEmulationWithArgc:gArgc argv:(char **)gArgv];

}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: applicationWillTerminate\n");

		//Cuando llega aqui la ventana ya esta cerrada. No hacer nada de refresco de ventana
		no_fadeout_exit.v=1;

    end_emulator();
    exit(0);
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

/*- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	end_emulator();
	return NSTerminateCancel;
}*/


- (void)startEmulationWithArgc:(int)argc argv:(char**)argv
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: startEmulationWithArgc\n");

    int status;
    status = zesarux_main(argc, argv);

   //porque hay un exit aqui?? quiza del main de zesarux no se deba volver nunca, dejar el bucle como pthread y listo
   // exit(status);
}


- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: openPanelDidEnd\n");
}
- (void)toggleFullScreen:(id)sender
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: toggleFullScreen\n");

    [cocoaView toggleFullScreen:sender];
}

- (void)showQEMUDoc:(id)sender
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: showQEMUDoc\n");

    [[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/../doc/qemu/qemu-doc.html",
        [[NSBundle mainBundle] resourcePath]] withApplication:@"Help Viewer"];
}

- (void)showQEMUTec:(id)sender
{
    //COCOA_DEBUG("ZesaruxCocoaAppController: showQEMUTec\n");

    [[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/../doc/qemu/qemu-tech.html",
        [[NSBundle mainBundle] resourcePath]] withApplication:@"Help Viewer"];
}

- (void) openzesaruxmenu:(id)sender
{
        //printf ("open zesarux menu\n");
        menu_fire_event_open_menu();
}

- (void) setzoomone:(id)sender
{
	screen_set_window_zoom(1);
}


@end



// Dock Connection
typedef struct CPSProcessSerNum
{
        UInt32                lo;
        UInt32                hi;
} CPSProcessSerNum;

OSErr CPSGetCurrentProcess( CPSProcessSerNum *psn);
OSErr CPSEnableForegroundOperation( CPSProcessSerNum *psn, UInt32 _arg2, UInt32 _arg3, UInt32 _arg4, UInt32 _arg5);
OSErr CPSSetFrontProcess( CPSProcessSerNum *psn);


//Retorna no 0 si se ha seleccionado un driver no cocoa por linea de comandos
int scrcocoa_non_cocoa_driver_set_cmd(int argc, const char * argv[])
{

	int i;

	// Si se especifica un video driver diferente de cocoa, no inicializar GUI
	for (i = 1; i < argc-1; i++) {

		//Por linea de comandos
		if (!strcmp(argv[i], "--vo") && strcmp(argv[i+1], "cocoa") ) return 1;
	}

	//O por archivo de configuración
	//TODO

	return 0;
}

int main (int argc, const char * argv[]) {

	gArgc = argc;
	gArgv = (char **)argv;


	// Si se especifica un video driver diferente de cocoa, no inicializar GUI

        if (scrcocoa_non_cocoa_driver_set_cmd(argc,argv) ) {
                //Y de aqui no salimos
                printf ("Running ZEsarUX in non GUI mode because a non cocoa video driver is selected\n\n");


                zesarux_main(gArgc, gArgv);


                //Bucle cerrado con sleep. El bucle main se ha lanzado como thread
                while (1) {
                        timer_sleep(1000);
                        //printf ("bucle con sleep\n");
                }

        }




	CPSProcessSerNum PSN;

        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        [NSApplication sharedApplication];
//	NSApplication *application = [NSApplication sharedApplication];

// de qemu
        if (!CPSGetCurrentProcess(&PSN))
                if (!CPSEnableForegroundOperation(&PSN,0x03,0x3C,0x2C,0x1103))
                        if (!CPSSetFrontProcess(&PSN))
                        [NSApplication sharedApplication];

//de ejemplos
/*
ProcessSerialNumber psn;

     GetCurrentProcess( &psn );
     CPSEnableForegroundOperation( &psn );
     SetFrontProcess( &psn );
*/

//de ejemplo
/*
ProcessSerialNumber psn;

if (!GetCurrentProcess(&psn))
{
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    SetFrontProcess(&psn);
}
*/

    // Add menus
    NSMenu      *menu;
    NSMenuItem  *menuItem;

    [NSApp setMainMenu:[[NSMenu alloc] init]];

    // Application menu
    menu = [[NSMenu alloc] initWithTitle:@""];
    [menu addItemWithTitle:@"About ZEsarUX" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""]; // About QEMU
    [menu addItem:[NSMenuItem separatorItem]]; //Separator
    [menu addItemWithTitle:@"Hide ZEsarUX" action:@selector(hide:) keyEquivalent:@""]; //Hide QEMU
    menuItem = (NSMenuItem *)[menu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@""]; // Hide Others

    //[menuItem setKeyEquivalentModifierMask:(NSAlternateKeyMask|NSCommandKeyMask)];
		[menuItem setKeyEquivalentModifierMask:(NSEventModifierFlagOption|NSEventModifierFlagCommand)];

    [menu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""]; // Show All

    [menu addItem:[NSMenuItem separatorItem]]; //Separator
    [menu addItemWithTitle:@"Quit ZEsarUX" action:@selector(terminate:) keyEquivalent:@""];
    menuItem = [[NSMenuItem alloc] initWithTitle:@"Apple" action:nil keyEquivalent:@""];
    [menuItem setSubmenu:menu];
    [[NSApp mainMenu] addItem:menuItem];
    [NSApp performSelector:@selector(setAppleMenu:) withObject:menu]; // Workaround (this method is private since 10.4+)

    // View menu
    menu = [[NSMenu alloc] initWithTitle:@"View"];
    [menu addItem: [[[NSMenuItem alloc] initWithTitle:@"Enter Fullscreen" action:@selector(toggleFullScreen:) keyEquivalent:@""] autorelease]]; // Fullscreen
    [menu addItem: [[[NSMenuItem alloc] initWithTitle:@"Open ZEsarUX menu" action:@selector(openzesaruxmenu:) keyEquivalent:@""] autorelease]];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"View" action:nil keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    [[NSApp mainMenu] addItem:menuItem];

    // Window menu
    menu = [[NSMenu alloc] initWithTitle:@"Window"];
    [menu addItem: [[[NSMenuItem alloc] initWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@""] autorelease]]; // Miniaturize
    //[menu addItem: [[[NSMenuItem alloc] initWithTitle:@"Minimize" action:@selector(performMiniaturize:) ] autorelease]]; // Miniaturize
    [menu addItem: [[[NSMenuItem alloc] initWithTitle:@"Set Zoom 1" action:@selector(setzoomone:) keyEquivalent:@""] autorelease]];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    [[NSApp mainMenu] addItem:menuItem];
    [NSApp setWindowsMenu:menu];

    // Help menu
    //menu = [[NSMenu alloc] initWithTitle:@"Help"];
    //[menu addItem: [[[NSMenuItem alloc] initWithTitle:@"QEMU Documentation" action:@selector(showQEMUDoc:) keyEquivalent:@""] autorelease]]; // QEMU Help
    //[menu addItem: [[[NSMenuItem alloc] initWithTitle:@"QEMU Technology" action:@selector(showQEMUTec:) keyEquivalent:@""] autorelease]]; // QEMU Help
    //menuItem = [[[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""] autorelease];
    //[menuItem setSubmenu:menu];
    //[[NSApp mainMenu] addItem:menuItem];

    // Create an Application controller
    ZesaruxCocoaAppController *appController = [[ZesaruxCocoaAppController alloc] init];

	//orig:
    [NSApp setDelegate:(id<NSApplicationDelegate>)appController];

    //[NSApp setDelegate:(ZesaruxCocoaAppController *)appController];
//[application setDelegate:appController];


    // Start the main event loop
//	printf ("\n\nrun app\n\n");

//temp
//[NSApp grabMouse];

    [NSApp run];


//	printf ("fin app\n");

    [appController release];
    [pool release];

    return 0;
}

#pragma mark zesarux


	

//Funcion de poner pixel en pantalla de driver, teniendo como entrada el color en RGB
void scrcocoa_putpixel_final_rgb(int x,int y,unsigned int color_rgb)
{


        int index = 4*(x+y*pixel_screen_width);
        unsigned int *p;
        p=(unsigned int *) &pixel_screen_data[index];

        //agregar alpha
        color_rgb |=0xFF000000;  
        //Escribir de golpe los 32 bits                 
        *p=color_rgb;
}

//Funcion de poner pixel en pantalla de driver, teniendo como entrada el color indexado de tabla de colores
void scrcocoa_putpixel_final(int x,int y,unsigned int color)
{

	if (pendingresize) {
		//debug_printf (VERBOSE_DEBUG,"putpixel with pendingresize active");
		return;
	}
                

        //Tabla con los colores reales del Spectrum. Formato RGB
        unsigned int color32=spectrum_colortable[color];

        //y escribir
        scrcocoa_putpixel_final_rgb(x,y,color32);
               

}

//int mostrado_trace=0;

//extern int running_realloc;

void scrcocoa_putpixel(int x,int y,unsigned int color)
{


        if (menu_overlay_activo==0) {
                //Putpixel con menu cerrado
                scrcocoa_putpixel_final(x,y,color);
                return;
        }          

/*if (buffer_layer_machine==NULL) {
        printf ("----buffer_layer_machine null running_realloc %d\n",running_realloc);
        debug_exec_show_backtrace();
        exit(1);
}*/


//temporal
/*if (x>=ancho_layer_menu_machine || y>=alto_layer_menu_machine)  {
        if (!mostrado_trace) {
                printf ("out of range scrcocoa_putpixel x %d y %d limit %d %d\n",x,y,ancho_layer_menu_machine,alto_layer_menu_machine);
                debug_exec_show_backtrace();
                mostrado_trace=1;
                sleep(1);
        }
        return;
}*/



        //Metemos pixel en layer adecuado
	buffer_layer_machine[y*ancho_layer_menu_machine+x]=color;   
   

        //Putpixel haciendo mix  
        screen_putpixel_mix_layers(x,y);   
}

void scrcocoa_putchar_zx8081(int x,int y, z80_byte caracter)
{
        scr_putchar_zx8081_comun(x,y, caracter);
}

void scrcocoa_debug_registers(void)
{

	char buffer[2048];
	print_registers(buffer);

	printf ("%s\r",buffer);
}

void scrcocoa_messages_debug(char *s)
{
        printf ("%s\n",s);
}

//Rutina de putchar para menu
void scrcocoa_putchar_menu(int x,int y, z80_byte caracter,int tinta,int papel)
{

        z80_bit inverse;

        inverse.v=0;

        //128 y 129 corresponden a franja de menu y a letra enye minuscula
        if (caracter<32 || caracter>MAX_CHARSET_GRAPHIC) caracter='?';
        scr_putchar_menu_comun_zoom(caracter,x,y,inverse,tinta,papel,menu_gui_zoom);

}

void scrcocoa_putchar_footer(int x,int y, z80_byte caracter,int tinta,int papel)
{

        int yorigen;


	yorigen=screen_get_emulated_display_height_no_zoom_bottomborder_en()/8;


        //scr_putchar_menu(x,yorigen+y,caracter,tinta,papel);
	y +=yorigen;
	//printf ("y: %d\n",y); entre 31,32 y 33 normalmente
	z80_bit inverse;

	inverse.v=0;

	//128 y 129 corresponden a franja de menu y a letra enye minuscula
	if (caracter<32 || caracter>MAX_CHARSET_GRAPHIC) caracter='?';
	//scr_putchar_menu_comun_zoom(caracter,x,y,inverse,tinta,papel,1);


        scr_putchar_footer_comun_zoom(caracter,x,y,inverse,tinta,papel);

}



void scrcocoa_set_fullscreen(void)
{

//[cocoaView toggleFullScreen:nil];

/*
A partir de OSX el capitan, la llamada
[cocoaView toggleFullScreen:nil];


genera este aviso al salir:
CoreAnimation: warning, deleted thread with uncommitted CATransaction; set CA_DEBUG_TRANSACTIONS=1 in environment to log backtraces.

Aparte que no funciona el full screen desde GUI settings. La solucion tiene el formato:
[cocoaView performSelectorOnMainThread:@selector(myCustomDrawing:)
                           withObject:myCustomData
                        waitUntilDone:YES];
*/

[cocoaView performSelectorOnMainThread:@selector(toggleFullScreen:) withObject:nil waitUntilDone:YES];


}


void scrcocoa_reset_fullscreen(void)
{
//[cocoaView toggleFullScreen:nil];
//Mismo comentario que set_fullscreen

[cocoaView performSelectorOnMainThread:@selector(toggleFullScreen:) withObject:nil waitUntilDone:YES];

}

void scrcocoa_refresca_pantalla_zx81(void)
{

	scr_refresca_pantalla_y_border_zx8081();

}


void scrcocoa_refresca_border(void)
{
        scr_refresca_border();

}

void scrcocoa_refresca_pantalla(void);

void scrcocoa_refresca_pantalla_solo_driver(void)
{
// Prueba para cuando se redimensiona ventana desde el easter egg
//if (pendingresize) scrcocoa_refresca_pantalla();

        
	[cocoaView render];


}



void scrcocoa_refresca_pantalla(void)
{

        //printf ("inicio scrcocoa_refresca_pantalla\n");

	if (pendiente_z88_draw_lower) {
		screen_z88_draw_lower_screen();
		pendiente_z88_draw_lower=0;
		menu_init_footer();
	}


        if (pendingresize) return;

	/*if (pendingresize && pendingresize_w!=0 && pendingresize_h!=0) {
		printf ("redimensionar desde refresca_pantalla\n");
		[normalWindow redimensionaVentana:pendingresize_w height:pendingresize_h];
		pendingresize=0;
	}*/

        if (sem_screen_refresh_reallocate_layers) {
                //printf ("--Screen layers are being reallocated. return\n");
                //debug_exec_show_backtrace();
                return;
        }

        sem_screen_refresh_reallocate_layers=1;



    if (MACHINE_IS_ZX8081) {
                //scr_refresca_pantalla_rainbow_comun();
                scrcocoa_refresca_pantalla_zx81();
    }

	else if (MACHINE_IS_PRISM) {
		screen_prism_refresca_pantalla();
	}

        else if (MACHINE_IS_TBBLUE) {
                screen_tbblue_refresca_pantalla();
        }

    else if (MACHINE_IS_SPECTRUM) {

		if (MACHINE_IS_TSCONF)	{
            screen_tsconf_refresca_pantalla();
        }


		else { //Spectrum no TSConf

                //modo clasico. sin rainbow
                if (rainbow_enabled.v==0) {
                        if (border_enabled.v) {
                                //ver si hay que refrescar border
                                if (modificado_border.v)
                                {
                                        scrcocoa_refresca_border();
                                        modificado_border.v=0;
                                }

                        }

                        scr_refresca_pantalla_comun();
                }

                else {
                //modo rainbow - real video
                        scr_refresca_pantalla_rainbow_comun();
                }

		}
    }

        else if (MACHINE_IS_Z88) {
                screen_z88_refresca_pantalla();
        }

	else if (MACHINE_IS_ACE) {
		scr_refresca_pantalla_y_border_ace();
	}

        else if (MACHINE_IS_CPC) {
                scr_refresca_pantalla_y_border_cpc();
        }

	else if (MACHINE_IS_SAM) {
		scr_refresca_pantalla_y_border_sam();
	}

	else if (MACHINE_IS_QL) {
		scr_refresca_pantalla_y_border_ql();
	}


	else if (MACHINE_IS_MK14) {
		scr_refresca_pantalla_y_border_mk14();
	}

	else if (MACHINE_IS_MSX) {
		scr_refresca_pantalla_y_border_msx();
	}   

	else if (MACHINE_IS_SVI) {
		scr_refresca_pantalla_y_border_svi();
	}                

	else if (MACHINE_IS_COLECO) {
		scr_refresca_pantalla_y_border_coleco();
	}      


	else if (MACHINE_IS_SG1000) {
		scr_refresca_pantalla_y_border_sg1000();
	}            

        //printf ("%d\n",spectrum_colortable[1]);

	if (menu_overlay_activo) {
                //printf ("antes de menu_overlay_function en cocoa\n");
                menu_overlay_function();
                //printf ("despues de menu_overlay_function en cocoa\n");
        }



        //Escribir footer
        draw_middle_footer();


        scrcocoa_refresca_pantalla_solo_driver();



        sem_screen_refresh_reallocate_layers=0;


}


void scrcocoa_end(void)
{
	debug_printf (VERBOSE_INFO,"Closing cocoa video driver");
}


void scrcocoa_z88_cpc_load_keymap(void)
{
	debug_printf (VERBOSE_INFO,"Loading keymap");

//Teclas se ubican en misma disposicion fisica del Z88, excepto:
        //libra~ -> spanish: cedilla (misma ubicacion fisica del z88). english: acento grave (supuestamente a la izquierda del 1)
        //backslash: en english esta en fila inferior del z88. en spanish, lo ubicamos a la izquierda del 1 (ºª\)

        //en modo raw, las teclas en driver cocoa retornan los mismos valores que un teclado english,
        //por tanto con esto podriamos mapear cualquier teclado fisico, sea ingles, spanish, danes o lo que sea,
        //y los codigos raw de retorno siempre son los mismos.
        //por tanto, devolvemos lo mismo que con keymap english siempre:

	if (MACHINE_IS_Z88 || MACHINE_IS_SAM || MACHINE_IS_QL || MACHINE_IS_MSX || MACHINE_IS_SVI) {
	                scrcocoa_keymap_z88_cpc_minus='-';
                        scrcocoa_keymap_z88_cpc_equal='=';
			scrcocoa_keymap_z88_cpc_backslash=COCOA_SECOND_BACKSLASH;

                        scrcocoa_keymap_z88_cpc_bracket_left='[';
                        scrcocoa_keymap_z88_cpc_bracket_right=']';
                        scrcocoa_keymap_z88_cpc_semicolon=';';
                        scrcocoa_keymap_z88_cpc_apostrophe='\'';
                        scrcocoa_keymap_z88_cpc_pound='\\';
                        scrcocoa_keymap_z88_cpc_comma=',';
                        scrcocoa_keymap_z88_cpc_period='.';
                        scrcocoa_keymap_z88_cpc_slash='/';
                        scrcocoa_keymap_z88_cpc_leftz='`'; //Tecla a la izquierda de la Z. Solo usada en Chloe
	}

	else if (MACHINE_IS_CPC) {
			scrcocoa_keymap_z88_cpc_minus='-';
			scrcocoa_keymap_z88_cpc_circunflejo='=';

			scrcocoa_keymap_z88_cpc_arroba='[';
			scrcocoa_keymap_z88_cpc_bracket_left=']';
			scrcocoa_keymap_z88_cpc_colon=';';
			scrcocoa_keymap_z88_cpc_semicolon='\'';
			scrcocoa_keymap_z88_cpc_bracket_right='\\';
			scrcocoa_keymap_z88_cpc_comma=',';
			scrcocoa_keymap_z88_cpc_period='.';
			scrcocoa_keymap_z88_cpc_slash='/';

			scrcocoa_keymap_z88_cpc_backslash=COCOA_SECOND_BACKSLASH;
                        scrcocoa_keymap_z88_cpc_leftz='`'; //Tecla a la izquierda de la Z. Solo usada en Chloe
	}

	//Para Chloe
	else if (MACHINE_IS_SPECTRUM && chloe_keyboard.v) {
                        scrcocoa_keymap_z88_cpc_minus='-';
                        scrcocoa_keymap_z88_cpc_equal='=';
                        scrcocoa_keymap_z88_cpc_backslash=COCOA_SECOND_BACKSLASH;

                        scrcocoa_keymap_z88_cpc_bracket_left='[';
                        scrcocoa_keymap_z88_cpc_bracket_right=']';
                        scrcocoa_keymap_z88_cpc_semicolon=';';
                        scrcocoa_keymap_z88_cpc_apostrophe='\'';
                        scrcocoa_keymap_z88_cpc_pound='\\';
                        scrcocoa_keymap_z88_cpc_comma=',';
                        scrcocoa_keymap_z88_cpc_period='.';
                        scrcocoa_keymap_z88_cpc_slash='/';
                        scrcocoa_keymap_z88_cpc_leftz='`'; //Tecla a la izquierda de la Z. Solo usada en Chloe
        }



        return;


}

z80_byte scrcocoa_lee_puerto(z80_byte puerto_h,z80_byte puerto_l)
{
	return 255;
}

void scrcocoa_actualiza_tablas_teclado(void)
{

	if (cocoa_enviar_caps_contador) {
		cocoa_enviar_caps_contador--;
		if (cocoa_enviar_caps_contador==0) {
			//printf ("liberar CAPS lock\n");
			util_set_reset_key(UTIL_KEY_CAPS_LOCK,0);
		}
	}


}

void scrcocoa_detectedchar_print(z80_byte caracter)
{
        printf ("%c",caracter);
        //flush de salida standard
        fflush(stdout);
}

//Estos valores no deben ser mayores de OVERLAY_SCREEN_MAX_WIDTH y OVERLAY_SCREEN_MAX_HEIGTH
int scrcocoa_get_menu_width(void)
{
        int max=screen_get_emulated_display_width_no_zoom_border_en();

        max +=screen_get_ext_desktop_width_no_zoom();

        max=max/menu_char_width/menu_gui_zoom;
        if (max>OVERLAY_SCREEN_MAX_WIDTH) max=OVERLAY_SCREEN_MAX_WIDTH;

                //printf ("max x: %d %d\n",max,screen_get_emulated_display_width_no_zoom_border_en());

        return max;
}


int scrcocoa_get_menu_height(void)
{
        int max=screen_get_emulated_display_height_no_zoom_border_en()/8/menu_gui_zoom;
        if (max>OVERLAY_SCREEN_MAX_HEIGTH) max=OVERLAY_SCREEN_MAX_HEIGTH;

                //printf ("max y: %d %d\n",max,screen_get_emulated_display_height_no_zoom_border_en());
        return max;
}


int scrcocoa_driver_can_ext_desktop (void)
{
        return 1;
}


int scrcocoa_init (void) {


	debug_printf (VERBOSE_INFO,"Init COCOA(OpenGL) Video Driver");


        //printf ("scrcocoa_init\n");

        int soyelmainthread;

        if ([NSThread isMainThread]) {
                //printf ("Soy el main thread\n");
                soyelmainthread=1;
        }

        else {
                //printf ("No soy el main thread\n");
                //Esto solo se puede hacer desde el main thread
                //dispatch_sync(dispatch_get_main_queue(), cocoaView toggleFullScreen:nil);
                soyelmainthread=0;
        }

        //Inicializaciones necesarias
        scr_putpixel=scrcocoa_putpixel;
        scr_putpixel_final=scrcocoa_putpixel_final;
        scr_putpixel_final_rgb=scrcocoa_putpixel_final_rgb;

        scr_get_menu_width=scrcocoa_get_menu_width;
        scr_get_menu_height=scrcocoa_get_menu_height;
        scr_driver_can_ext_desktop=scrcocoa_driver_can_ext_desktop;

        scr_putchar_zx8081=scrcocoa_putchar_zx8081;
        scr_debug_registers=scrcocoa_debug_registers;
        scr_messages_debug=scrcocoa_messages_debug;
        scr_putchar_menu=scrcocoa_putchar_menu;
        scr_putchar_footer=scrcocoa_putchar_footer;
        scr_set_fullscreen=scrcocoa_set_fullscreen;
        scr_reset_fullscreen=scrcocoa_reset_fullscreen;
	scr_z88_cpc_load_keymap=scrcocoa_z88_cpc_load_keymap;
	scr_detectedchar_print=scrcocoa_detectedchar_print;
        scr_tiene_colores=1;
        screen_refresh_menu=1;


        //Otra inicializacion necesaria
        //Esto debe estar al final, para que funcione correctamente desde menu, cuando se selecciona un driver, y no va, que pueda volver al anterior
        scr_driver_name="cocoa";

	scr_z88_cpc_load_keymap();



        pixel_screen_width = screen_get_window_size_width_zoom_border_en()+screen_get_ext_desktop_width_zoom();
        pixel_screen_height = screen_get_window_size_height_zoom_border_en();

   

//screen_get_window_size_width_zoom_border_en(), screen_get_window_size_height_zoom_border_en()

        NSInteger dataLength = pixel_screen_width * pixel_screen_height * 4;
        //UInt8 *pixel_screen_data = (UInt8*)malloc(dataLength * sizeof(UInt8));
        pixel_screen_data = (UInt8*)malloc(dataLength * sizeof(UInt8));

    scr_reallocate_layers_menu(pixel_screen_width,pixel_screen_height);     

        //Esto tiene que llamarlo desde el thread principal:
        dispatch_async(dispatch_get_main_queue(), ^{
   [cocoaView resizeContentToWidth:(int)(pixel_screen_width) height:(int)(pixel_screen_height) ];
        });


	if (ventana_fullscreen) {
		//esto no lo hace bien. se queda la ventana con un escalado raro, y ademas en gui settings dice que fullscreen=0
		[cocoaView toggleFullScreen:nil];
	}


	return 0;
}

