module main

import os
// import time
import math as mx
import miniaudio as ma
import gg
import gx
import arrays
const bg_color	= gg.Color{0, 0, 0, 0}
const five_second	= 480*5*60
const tour		= mx.pi/32

const ext_sound	= ["flac", "mp3"]

const commands	= "escape: close the app \n
space:  pause\n
f:      fullscreen\n

right:  +5s\n
left:   -5s\n
up:     V+\n
down:   V-\n

t:  rotate the sound left to right\n
y:  set the sound in front of you\n
u:  rotate the sound left to right\n

i:  show help
"
const text_commands	= commands.split("\n")
const text_config	= gx.TextCfg{
		color:          gx.black
		size:           20
		align:          .left
		vertical_align: .top
	}

struct App {
	mut:
	ctx		&gg.Context = unsafe { nil }

	// Sons
	engine		ma.Engine	= ma.Engine{}
	sounds_dir	string
	sounds		[]ma.Sound	= [ma.Sound{}]
	sounds_len	[]u64

	is_playing	int

	volume		f32	= 10

	// Prams
	angle	f64		= 0.0
	pause	bool	= true

	help	bool	= true

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
		window_title: '- sound 3D -'
		user_data: app
		bg_color: bg_color
		init_fn:  on_init
		frame_fn: on_frame
		event_fn: on_event
		sample_count: 4
	)

	app.basedir = os.real_path(os.join_path(os.dir(@FILE)))
	app.sounds_dir = os.join_path(app.basedir, 'Musics')

	// mut engineconfig := ma.engine_config_init()
	// engineconfig.noDevice   = ma.true
	// engineconfig.channels   = 2        // Must be set when not using a device.
	// engineconfig.sampleRate = 48000    // Must be set when not using a device.

	if ma.engine_init(ma.null, app.engine) != .success {
		panic('Failed to initialize audio engine.')
	}
	ma.engine_listener_set_position(app.engine, 0, 0, 0, 0)
	ma.engine_listener_set_cone(app.engine, 0, 1, 3, 0.5)
	ma.sound_set_volume(app.sounds[app.is_playing], app.volume)

	// Init sounds
	mut names_list := []string{}
	for ext in ext_sound{
		names_list = arrays.append(names_list, os.walk_ext(app.sounds_dir, ext))
	}
	print(names_list)
	app.sounds	= []ma.Sound{len: names_list.len, init:ma.Sound{}}

	mut i := 0
	for wav_file in names_list{
		app.sounds[i] = ma.Sound{}

		if ma.sound_init_from_file(app.engine, wav_file.str, 0, ma.null, ma.null, &app.sounds[i]) != .success {
			panic('Failed to load and play "${wav_file}".')
		}

		ma.sound_set_pinned_listener_index(app.sounds[i], 0)
		ma.sound_set_position(app.sounds[i], 2, 0, 0)

		i += 1
	}

	// length
	mut length := u64(0)
	app.sounds_len = []u64{len: app.sounds.len, init: 0}
	for ind in 0..app.sounds.len{
		if ma.sound_get_length_in_pcm_frames(&app.sounds[ind], &length) != .success {
			panic('Failed to retrieve the length.') // Failed to retrieve the length.
		}
		app.sounds_len[ind] = length
	}

	// background
	app.background = app.ctx.create_image(os.join_path(app.basedir, 'back.jpg'))!

	// Real start
	println("Start")
	app.ctx.run()

	// End
	app.exit()
}

fn on_init(mut app App){
	size := app.ctx.window_size()
	app.ctx.width 		= size.width
	app.ctx.height 		= size.height
}

fn on_frame(mut app App){
	// Direction
	x := f32(mx.cos(app.angle))
	z := f32(mx.sin(app.angle))
	ma.engine_listener_set_direction(app.engine, 0, x, 0, z)

	// Change
	if ma.sound_at_end(app.sounds[app.is_playing]) == 1{
		if app.is_playing < app.sounds.len - 1{
			app.is_playing += 1
		}
		else{
			app.is_playing = 0
		}
		ma.sound_set_volume(app.sounds[app.is_playing], app.volume)
		ma.sound_seek_to_pcm_frame(app.sounds[app.is_playing], 0)
		ma.sound_start(&app.sounds[app.is_playing])
	}

	// Front
	app.ctx.begin()
	app.ctx.draw_image(0, 0, app.ctx.width, app.ctx.height, app.background)
	app.ctx.draw_rounded_rect_filled(5, app.ctx.height - 25, app.ctx.width - 10, 20, 10, gg.Color{0, 0, 0, 255})
	app.ctx.draw_rounded_rect_filled(10, app.ctx.height - 20, app.ctx.width - 20, 10, 5, gg.Color{122, 122, 122, 255})

	// Affichage Pause
	if app.pause{
		mid_x := f32(app.ctx.width/2)
		mid_y := f32(app.ctx.height/2)

		// Left
		app.ctx.draw_rect_filled(mid_x - 25, mid_y - 30, 20, 40, gg.Color{122, 122, 122, 255})

		// Right
		app.ctx.draw_rect_filled(mid_x + 5, mid_y - 30, 20, 40, gg.Color{122, 122, 122, 255})
	}

	// Affichage volume
	app.ctx.draw_rect_filled(app.ctx.width - 65, 0, 65, 20, gg.Color{122, 122, 122, 255})
	app.ctx.draw_text(app.ctx.width - 65, 0, "${int(app.volume)}/100", text_config)

	// Affichage Commands
	if app.help{
		app.ctx.draw_rect_filled(0, 0, 250, 10 + 10*text_commands.len, gg.Color{122, 122, 122, 255})
		mut n := 0
		for txt in text_commands{
			app.ctx.draw_text(10, 10 + 10*n, txt, text_config)
			n += 1
		}
	}

	// Progresse
	taille := int((app.ctx.width - 20)*(f64(ma.sound_get_time_in_pcm_frames(&app.sounds[app.is_playing]))/f64(app.sounds_len[app.is_playing])))
	app.ctx.draw_rounded_rect_filled(10, app.ctx.height - 20, taille, 10, 5, gg.Color{255, 0, 0, 255})
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
					
					if ma.sound_is_playing(app.sounds[app.is_playing]) == 1{
						ma.sound_stop(&app.sounds[app.is_playing])
						app.pause = true
						println('Pause')
					}
					else{
						ma.sound_start(&app.sounds[app.is_playing])
						app.pause = false
						println("Play")
					}
				}
				.left{
					if ma.sound_get_time_in_pcm_frames(&app.sounds[app.is_playing]) > five_second{
						ma.sound_seek_to_pcm_frame(app.sounds[app.is_playing], ma.sound_get_time_in_pcm_frames(&app.sounds[app.is_playing]) - five_second)
					}
					else{
						ma.sound_seek_to_pcm_frame(app.sounds[app.is_playing], 0)
					}
				}
				.right{
					if ma.sound_get_time_in_pcm_frames(&app.sounds[app.is_playing])  + five_second < app.sounds_len[0]{
						ma.sound_seek_to_pcm_frame(app.sounds[app.is_playing], ma.sound_get_time_in_pcm_frames(&app.sounds[app.is_playing]) + five_second)
					}
					else{
						ma.sound_seek_to_pcm_frame(app.sounds[app.is_playing], 0)
					}
				}
				.up{
					if app.volume < 100{
						app.volume += 1
						ma.sound_set_volume(app.sounds[app.is_playing], app.volume)
					}
				}
				.down{
					if app.volume > 1{
						app.volume -= 1
						ma.sound_set_volume(app.sounds[app.is_playing], app.volume)
					}
				}
				.t{
					app.angle += tour
				}
				.y{
					app.angle = 0
				}
				.u{
					app.angle -= tour
				}
				.i{
					app.help = !app.help
				}
				.f{
					gg.toggle_fullscreen()
				}
				else{}
			}
		}
		else{}
	}
}

fn (app App) exit(){
	// Déconnexion
	for sound in app.sounds{
		ma.sound_stop(&sound)
		ma.sound_uninit(sound)
	}

	ma.engine_uninit(app.engine)
	app.ctx.quit()
	print("Quit")
}
