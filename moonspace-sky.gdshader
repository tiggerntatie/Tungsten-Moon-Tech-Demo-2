shader_type sky;

uniform float sky_energy = 1.0; // In Lux.
uniform vec4 sky_cover_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float sun_angle_max = 0.6; // degrees
uniform sampler2D star_field : source_color, hint_default_transparent, filter_nearest;
uniform float sun_curve : hint_range(0, 1) = 0.15;

void sky() {

	if (AT_CUBEMAP_PASS) {
		COLOR = vec3(0.0,0.0,0.0);
	} else {
		vec3 sky = vec3(0.0);
		if (LIGHT0_ENABLED) {
			float sun_angle = distance(EYEDIR, LIGHT0_DIRECTION);
			if (sun_angle < LIGHT0_SIZE) {
				sky = LIGHT0_COLOR * LIGHT0_ENERGY;
			} else if (sun_angle < sun_angle_max) {
				float c2 = (sun_angle - LIGHT0_SIZE) / (sun_angle_max - LIGHT0_SIZE);
				sky = mix(LIGHT0_COLOR * LIGHT0_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
			}
		}
		vec4 sky_cover_texture =  texture(star_field, SKY_COORDS);
		sky += (sky_cover_texture.rgb * sky_cover_modulate.rgb) * sky_cover_texture.a * sky_cover_modulate.a * sky_energy;
		COLOR = sky;
	}
}
