shader_type sky;

uniform float sky_energy = 1.0; // In Lux.
uniform vec4 sky_cover_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D star_field : source_color, hint_default_transparent, filter_nearest;
uniform float sun_curve : hint_range(0, 1) = 0.15;
uniform float rotation = 0.0;

void sky() {
	bool sun_rendered = false;
	bool planet_rendered = false;
	if (AT_CUBEMAP_PASS) {
		COLOR = vec3(0.0,0.0,0.0);
	} else {
		vec3 sky = vec3(0.0);
		if (LIGHT0_ENABLED) {
			float sun_angle = distance(EYEDIR, LIGHT0_DIRECTION);
			float sun_angle_max = LIGHT0_SIZE * 1.3;
			if (sun_angle < LIGHT0_SIZE) {
				sun_rendered = true;
				sky += LIGHT0_COLOR * LIGHT0_ENERGY;  // the central disk
			} else if (sun_angle < sun_angle_max) {
				sun_rendered = true;
				float c2 = (sun_angle - LIGHT0_SIZE) / (sun_angle_max - LIGHT0_SIZE);
				sky += mix(LIGHT0_COLOR * LIGHT0_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0)); // the corona
			}
		}
		if (LIGHT1_ENABLED) {
			float p_angle = distance(EYEDIR, LIGHT1_DIRECTION);
			if (p_angle < LIGHT1_SIZE) {
				planet_rendered = true;
				float alpha = PI - asin(sin(p_angle)/LIGHT1_SIZE); 
				float beta = PI - p_angle - alpha;
				vec3 vr_s = EYEDIR*(sin(beta)/sin(alpha)); // distance vector to planet surface along sightline (less than unit length)
				vec3 v_r = vr_s - LIGHT1_DIRECTION;  // vector, center of planet to surface point
				if (dot(v_r, LIGHT0_DIRECTION) > 0.0) {
					sky = LIGHT1_COLOR * LIGHT1_ENERGY;  // point seen is facing sun
				} else {
					sky = vec3(0.01);
				}
			}
		}
		//float newx = SKY_COORDS.x + (rotation/360.0) - floor(rotation/360.0);
		//if (newx < 0.0) newx += 1.0;
		if (!planet_rendered) {
			vec2 rotated_sky = vec2(SKY_COORDS.x + (rotation/2.0/PI), SKY_COORDS.y);
			vec4 sky_cover_texture =  texture(star_field, rotated_sky);
			sky += (sky_cover_texture.rgb * sky_cover_modulate.rgb) * sky_cover_texture.a * sky_cover_modulate.a * sky_energy;
		}
		COLOR = sky;
	}
}
