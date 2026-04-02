#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define ITER 128

vec3 hsv(float h,float s,float v) {
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

void main( void ) {
    const float ITER_F = float(ITER);
    vec2 scrpos = gl_FragCoord.xy / resolution.xy;
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = surfacePos*3.0;
    float a = time*0.3;
    vec2 z = p;
    vec2 c = vec2(sin(time*454354.5345345), cos(time*123453.5454534));
    vec2 o = vec2(0)*0.1+0.5;
    vec2 zp = vec2(1);
    float iter = 0.0;
    float m2;
    
    for (int i = 0; i < ITER; i++) {
        zp = 2.0*vec2(z.x*zp.x - z.y*zp.y, z.x*zp.y + z.y*zp.x);
        z = vec2(2.0*z.x*z.y, z.y*z.y - z.x*z.x) + c;
        m2 = dot(z, z);
        
        if (m2 > 1000.0) {
            break;
        }
        iter++;
    }
    if (iter > ITER_F-1.0) {
        vec2 p = (scrpos-o)*1.007+o;
        vec4 last = texture2D(backbuffer, p);
        float v = last.a + 0.01;
        glFragColor = vec4(hsv(v, dot(last,last), length(last.rgb)*0.9), fract(v));    
    } else if (iter < 16.0) {
        vec2 p = (scrpos-o)*0.993+o;
        vec4 last = texture2D(backbuffer, p);
        float v = last.a - 0.01;
        glFragColor = vec4(hsv(v, dot(last,last), length(last.rgb)*0.9), fract(v));    
    } else {
        float c = sqrt(m2/dot(zp, zp))*1.0*log(m2);
        glFragColor = vec4(hsv(c, 1.0, min(1.0-c*8.0, 1.0)), fract(c));

    }

}
