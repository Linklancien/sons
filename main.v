module main

import os
import time
import miniaudio as ma
import gg

const bg_color = gg.Color{0, 0, 0, 0}

struct App {
	mut:
	ctx		&gg.Context = unsafe { nil }

	// Sons
	engine	&ma.Engine
	sounds	[]ma.Sound	=	[ma.Sound{}]

	// Files
	basedir string

	// Graphics
	background gg.Image
}

fn main() {
	mut app := &App{engine: &ma.Engine{}}
	app.ctx = gg.new_context(
		fullscreen: false
		width: 100*8
		height: 100*8
		create_window: true
		window_title: '- 3D -'
		user_data: app
		bg_color: bg_color
		init_fn:  on_init
		frame_fn: on_frame
		event_fn: on_event
		sample_count: 4
	)

	app.basedir = os.real_path(os.join_path(os.dir(@FILE)))
	wav_file := os.join_path(app.basedir, 'audio.flac')

	// mut engineconfig := ma.engine_config_init()
	// engineconfig.noDevice   = ma.true
	// engineconfig.channels   = 2        // Must be set when not using a device.
	// engineconfig.sampleRate = 48000    // Must be set when not using a device.

	result := ma.engine_init(ma.null, app.engine)
	if result != .success {
		panic('Failed to initialize audio engine.')
	}
	ma.engine_listener_set_position(app.engine, 0, 0, 0, 0)
	// ma.engine_listener_set_direction(app.gg.engine, 0, 0, 0, 0)
	ma.engine_listener_set_cone(app.engine, 0, 1, 3, 0.5)

	// Sound
	app.sounds[0] = ma.Sound{}

	if ma.sound_init_from_file(app.engine, wav_file.str, 0, ma.null, ma.null, &app.sounds[0]) != .success {
		panic('Failed to load and play "${wav_file}".')
	}
	
	println("playing ${wav_file}")

	ma.sound_set_pinned_listener_index(app.sounds[0], 0)
	ma.sound_set_position(app.sounds[0], 0, 0, 0)

	// ma.sound_start(&app.sounds[0])
	
	// background
	app.background = app.ctx.create_image(os.join_path(app.basedir, 'back.jpg'))!


	app.ctx.run()
	app.exit()
}

fn on_init(mut app App){
	size := app.ctx.window_size()
	app.ctx.width 		= size.width
	app.ctx.height 		= size.height
}

fn on_frame(mut app App){
	if ma.sound_at_end(&app.sounds[0]) != 1{
		println(ma.sound_get_time_in_pcm_frames(&app.sounds[0]))
	}
	
	// 	time.sleep(100 * time.millisecond)
	// 	ma.sound_set_volume(&sound, 1)
	// 	println(ma.sound_get_volume(&sound))
	// 	println("$t, ${2*m.sin(t)}, ${2*m.cos(t)} ")
	// }

	app.ctx.begin()
	app.ctx.draw_image(0, 0, app.ctx.width, app.ctx.height, app.background)
	app.ctx.end()
}

fn on_event(e &gg.Event, mut app App){
	size := app.ctx.window_size()
	app.ctx.width 		= size.width
	app.ctx.height 		= size.height

	match e.typ {
		.key_down {
			match e.key_code{
				.escape{
					app.exit()
				}
				.space{
					
					if ma.sound_is_playing(app.sounds[0]) == 1{
						ma.sound_stop(&app.sounds[0])
						print('Pause')
					}
					else{
						ma.sound_start(&app.sounds[0])
						print("Start")
					}
				}
				.left{

				}
				.right{
					
				}
				else{}
			}
		}
		else{}
	}
}

fn (app App) exit(){
	// Déconnexion
	ma.engine_uninit(app.engine)
	for sound in app.sounds{
		ma.sound_stop(&sound)
		ma.sound_uninit(sound)
	}
	app.ctx.quit()
	print("Quit")
}
