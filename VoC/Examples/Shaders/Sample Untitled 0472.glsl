#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NUM 51.
#define THCKN .001
#define PI  3.1415926
#define PI2 6.2831853

void main() {
    vec2 lM = vec2(max(resolution.x, resolution.y), min(resolution.x, resolution.y));
    vec2 pos = (gl_FragCoord.xy -.5 * lM) / lM.x;
    float pix = fwidth(pos.x);
    float an = (PI2/NUM);
        for (float i = 0.; i < NUM; i++)  {  
          float dn = i * an;
            float timed = time * .1 + dn;
            float wave = .44 - (.15 + .15 * sin(time*.5));
            vec2 circPos = vec2(
                sin(timed) * wave,
                cos(timed) * wave
            );
            vec4 mate = vec4(sin(dn+time),sin(-dn)*cos(-dn),cos(dn+time),1.);
            float dist = abs(distance((pos), circPos) - .52 + THCKN);
            if(dist < THCKN) {
                glFragColor = mix(vec4(0.,0.,0.,1.), mate, 1.-abs(dist));
                return;
            }
        }
    glFragColor = vec4(0.,0.,0.,1.);
}
