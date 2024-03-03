shader_type sky;

uniform float rotation;
uniform vec2 viewport;

float rand(vec2 co)
{
    return fract(sin(dot(co ,vec2(12.9898,78.233))) * 43758.5453);
	//return fract(abs(co.x * co.y * 1000000.0));
}

void sky() {	
	//vec2 pos = floor(viewport.x * vec2((PI/2.0)*(SKY_COORDS.x-0.5) * sin((PI/2.0)*(SKY_COORDS.y-0.5)), SKY_COORDS.y))/(viewport.x);
	//vec2 pos = vec2(SKY_COORDS.x * cos(SKY_COORDS.y), SKY_COORDS.x) / viewport;
	//vec2 pos = vec2(atan(EYEDIR.z, EYEDIR.x), asin(EYEDIR.y));
	//vec2 pos = floor(1.0 / 100.0 * FRAGCOORD.xy);
	vec3 ed = floor(500.0*EYEDIR)/500.0;
	vec2 pos = vec2(atan(ed.z, ed.x), atan(ed.y, sqrt(ed.x*ed.x + ed.z*ed.z)));
	pos = vec2(pos.x * cos(pos.y), pos.y);
	//pos = floor(pos*100.0)/100.0;
	if (rand(pos) > 0.995) {
		COLOR = vec3(1.0,1.0,1.0);
	}
	
	if (LIGHT0_ENABLED) {
		const float cosradius = cos(LIGHT0_SIZE/2.0);
		if (dot(EYEDIR, LIGHT0_DIRECTION) >= cosradius) {
			COLOR = LIGHT0_COLOR;
		}
	}
}
