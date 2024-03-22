shader_type sky;

uniform float sky_energy = 1.0; // In Lux.
uniform vec4 sky_cover_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D star_field : source_color, hint_default_transparent, filter_nearest;
// https://opengameart.org/content/planet-texture-80004000px-planet8png
uniform sampler2D planet_albedo : source_color, hint_default_transparent, filter_nearest;
uniform float planet_dark_side_albedo_factor = 0.002;
uniform vec4 planet_rotation = vec4(0.0, 0.0, 0.0, 0.0);
uniform float planet_default_light_energy = 1.0; 
uniform float planet_size_degrees = 10.0;
uniform float sun_curve : hint_range(0, 1) = 0.15;
uniform float sun_size_degrees = 0.5;
uniform float star_rotation = 0.0;
uniform float star_energy = 1.0;

void sky() {
	bool sun_rendered = false;
	bool planet_rendered = false;
	if (AT_CUBEMAP_PASS) {
		COLOR = vec3(0.0,0.0,0.0);
	} else {
		vec3 sky = vec3(0.0);
		if (LIGHT0_ENABLED) {
			float light0_radius = radians(sun_size_degrees/2.0);
			float sun_angle = distance(EYEDIR, LIGHT0_DIRECTION);
			float sun_angle_max = light0_radius * 1.3;
			if (sun_angle < light0_radius) {
				sun_rendered = true;
				sky += LIGHT0_COLOR * LIGHT0_ENERGY;  // the central disk
			} else if (sun_angle < sun_angle_max) {
				sun_rendered = true;
				float c2 = (sun_angle - light0_radius) / (sun_angle_max - light0_radius);
				sky += mix(LIGHT0_COLOR * LIGHT0_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0)); // the corona
			}
		}
		if (LIGHT1_ENABLED) {
			float light1_radius = radians(planet_size_degrees/2.0);
			float planet_radius = sqrt(2.0 - 2.0*cos(light1_radius));
			float p_angle = distance(EYEDIR, LIGHT1_DIRECTION);
			if (p_angle < light1_radius) {
				planet_rendered = true;
				float alpha = PI - asin(sin(p_angle)/planet_radius); 
				float beta = PI - p_angle - alpha;
				vec3 vr_s = EYEDIR*(sin(beta)/sin(alpha)); // distance vector to planet surface along sightline (less than unit length)
				vec3 v_rn = normalize(vr_s - LIGHT1_DIRECTION);  // vector, center of planet to surface point
				float surface_illumination = dot(v_rn, LIGHT0_DIRECTION);
				float shadow_factor = surface_illumination > 0.0 ? 1.0 : planet_dark_side_albedo_factor;
				// find surface coordinates in planet-local frame
				vec3 temp = cross(planet_rotation.xyz, v_rn) + planet_rotation.w * v_rn;
				vec3 rotated_v_rn = v_rn + 2.0*cross(planet_rotation.xyz, temp);
				vec2 v_ps = vec2(atan(rotated_v_rn.z, rotated_v_rn.x)/PI, asin(rotated_v_rn.y)/PI+0.5);
				// grab the correct pixel color from the planet texture, but 
				// take into account the overall albedo, planet illumination angle, and moon-shine brightness
				sky = planet_default_light_energy * surface_illumination * shadow_factor * texture(planet_albedo, v_ps).rgb;
			}
		}
		//float newx = SKY_COORDS.x + (rotation/360.0) - floor(rotation/360.0);
		//if (newx < 0.0) newx += 1.0;
		if (!planet_rendered) {
			vec2 rotated_sky = vec2(SKY_COORDS.x + (star_rotation/2.0/PI), SKY_COORDS.y);
			vec4 sky_cover_texture =  texture(star_field, rotated_sky);
			sky += (sky_cover_texture.rgb * sky_cover_modulate.rgb) * sky_cover_texture.a * sky_cover_modulate.a * sky_energy * star_energy;
		}
		COLOR = sky;
	}
}
