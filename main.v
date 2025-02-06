module main

import os
import time
import miniaudio as ma
import math as m

fn main() {
	basedir := os.real_path(os.join_path(os.dir(@FILE)))
	wav_file := os.join_path(basedir, 'audio.flac')

	engine := &ma.Engine{}

	// mut engineconfig := ma.engine_config_init()
	// engineconfig.noDevice   = ma.true
	// engineconfig.channels   = 2        // Must be set when not using a device.
	// engineconfig.sampleRate = 48000    // Must be set when not using a device.

	result := ma.engine_init(ma.null, engine)
	if result != .success {
		panic('Failed to initialize audio engine.')
	}
	ma.engine_listener_set_position(engine, 0, 0, 0, 0)
	// ma.engine_listener_set_direction(engine, 0, 0, 0, 0)
	ma.engine_listener_set_cone(engine, 0, 1, 3, 0.5)

	// Sound
	sound := ma.Sound{}

	if ma.sound_init_from_file(engine, wav_file.str, 0, ma.null, ma.null, &sound) != .success {
		panic('Failed to load and play "${wav_file}".')
	}
	
	println("playing ${wav_file}")

	ma.sound_set_pinned_listener_index(sound, 0)
	// ma.sound_set_pan(sound, 1)
	ma.sound_set_position(sound, 0, 0, 3)

	ma.sound_start(&sound)
	mut t := 0.0
	for ma.sound_at_end(&sound) != 1{
		time.sleep(100 * time.millisecond)
		// ma.sound_set_volume(&sound, 1)
		// println(ma.sound_get_volume(&sound))
		t += 0.05
		// println("$t, ${2*m.sin(t)}, ${2*m.cos(t)} ")
		ma.sound_set_position(sound, f32(2*m.sin(t)), 0, f32(2*m.cos(t)))
	}
	

	// Déconnexion
	ma.engine_uninit(engine)
	ma.sound_uninit(sound)
}