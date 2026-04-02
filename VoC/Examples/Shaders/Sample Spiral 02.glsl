#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv(float h,float s,float v) {
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

void main( void ) {
    vec2 p =-1.0+2.0* ( gl_FragCoord.xy / resolution.xy );
    p.x *= resolution.x/resolution.y;
    float iter = 0.0;
    float s = sin(time*0.1);
    float c = cos(time*0.1);
    vec3 col = vec3(0);
    for (int i = 0; i < 100; i++) {
        p = vec2(p.x*p.x*(1.0*p.y-p.x)+p.y, p.y*p.y*(1.0*p.x-p.y)+p.x);
        p = vec2(s*p.y+c*p.x, s*p.x-c*p.y);
        //if (dot(p,p) >2.0) break;
        col += hsv(dot(p,p),0.3,0.05)*smoothstep(16.0,0.0,dot(p,p));
        iter++;
    }

    glFragColor = vec4( sin(col), 1.0 );

}
