#version 420

// original https://www.shadertoy.com/view/Nl3GDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float NUM_ITERATIONS = 512.0;
const float zoomSpeed = 10.0;
const float width = 5.0;
//const vec2 center = vec2(-0.742978, 0.1);
const vec2 center = vec2(-0.747005, 0.150006);

vec2 f(vec2 z, vec2 c) {    
    return vec2(z.x * z.x - z.y * z.y, 2.0 * z.y * z.x) + c;
}

float iter(vec2 c) {

    float nrm = dot(c, c);
    // http://iquilezles.org/www/articles/mset_1bulb/mset1bulb.htm
    if( 256.0*nrm*nrm - 96.0*nrm + 32.0*c.x - 3.0 < 0.0 ) return 0.0;
    // http://iquilezles.org/www/articles/mset_2bulb/mset2bulb.htm
    if( 16.0*(nrm+2.0*c.x+1.0) - 1.0 < 0.0 ) return 0.0;
    
    vec2 z = vec2(0.0, 0.0);
    float i;
    for (i = 0.0; i < NUM_ITERATIONS; i += 1.0) {
        z = f(z, c);
        if (dot(z, z) > 4.0) break;
    }
    if (i >= NUM_ITERATIONS) 
        return 0.0;  
        
    // smooth out the coloring
    float si = i - log2(log2(dot(z,z))) + 4.0;
    float ai = smoothstep( -0.1, 0.0, 0.0);
    i = mix(i, si, ai);

    return i;
}

vec2 rotateCoord(vec2 c) {
    float theta = 3.14 + 3.14 * cos(time / 10.0);
    float x = (c.x - center.x) * cos(theta) - (c.y - center.y) * sin(theta) + center.x;
    float y = (c.x - center.x) * sin(theta) + (c.y - center.y) * cos(theta) + center.y;
    return vec2(x, y);
    
}

vec2 transformCoord() {
    float rescale = pow(zoomSpeed, -3.0 + 3.0*cos(time / 10.0));
    vec2 size = vec2(width, resolution.y / resolution.x * width) * rescale;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    return rotateCoord((uv - 0.5) * size + center);
}

void main(void)
{
    vec2 c = transformCoord();
    float i = iter(c);    
    // color calculation
    vec3 col = 0.5 + 0.5*cos( 3.0 + i*0.05 + vec3(0.50, 0.00, 0.05));
    glFragColor = vec4(col, 1.0);
}

