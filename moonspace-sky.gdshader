shader_type sky;

uniform float rotation;
uniform vec2 viewport;

float hash(vec2 co)
{
    return fract(sin(dot(co ,vec2(12.9898,78.233))) * 43758.5453);
}

void sky() {	
	
	//vec2 eyell = vec2(atan(EYEDIR.x,EYEDIR.z), atan(EYEDIR.y, length(vec2(EYEDIR.x,EYEDIR.z))));
	//vec2 eyelln = vec2(-eyell.x/(2.0*PI) + 0.5, -eyell.y/PI + 0.5); // this gives SKY_COORDS perfectly
	//COLOR = vec3(eyelln.x, eyelln.y, 0.0);	
	//COLOR = vec3(SKY_COORDS.x, SKY_COORDS.y, 0.0);
	float y = ceil(SKY_COORDS.y*1000.0)/1000.0;
	float xn = ceil(1000.0*cos(-PI*(SKY_COORDS.y-0.5)));
	float x = ceil(SKY_COORDS.x*xn)/1000.0;
	float p = hash(vec2(x,y));
	if (p > 0.996) {
		COLOR = vec3(1.0, 1.0, 1.0);
	}
	
	if (LIGHT0_ENABLED) {
		const float cosradius = cos(LIGHT0_SIZE/2.0);
		if (dot(EYEDIR, LIGHT0_DIRECTION) >= cosradius) {
			COLOR = LIGHT0_COLOR;
		}
	}
}
