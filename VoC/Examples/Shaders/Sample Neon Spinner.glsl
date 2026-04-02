#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// neon spinner, nodj.

#define PI       3.14159265359
#define SCALE    1.
#define N        12.
#define R        0.45
#define W        mouse.x*PI
#define CONTRAST 1.7
#define SPEED    1.
#define OFFSET   10.98
#define E0       0.4
#define E        200.
#define SAT      0.75
#define TWIST    0.75
const float radius   = 0.33;
const vec3 color1 = 0.8*vec3(0.2,0.9,0.7);
const vec3 color2 = vec3(1.1,0.05,0.05);

float a,r;
vec2 p;

float d2y(float d){return 1./(E0+d);}
float angle(){return atan(p.y, p.x);}
float dCircle(float radius){ return abs(r-radius); }
vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float dArc(float radius, float a0, float a1){
    float f = floor(a0/(2.*PI));
    a0-=f*2.*PI;
    a1-=f*2.*PI;
    float am = a;
    
    float dc = dCircle(radius);
    float dc0 = dc+100000.*(1.-step(a0,am)*step(am,a1));
    am +=2.*PI;
    dc0 = min(dc0,dc+100000.*(1.-step(a0,am)*step(am,a1)));
    
    float da0 = distance(p, radius*vec2(cos(a0), sin(a0)));
    float da1 = distance(p, radius*vec2(cos(a1), sin(a1)));
    
    return min(dc0,min(da1,da0));
}

void main() {

    p = SCALE*(gl_FragCoord.xy-0.5*resolution)/ resolution.y;
    a = angle();
    r = length(p);
    
    vec3 rgb = vec3(0.);
    float t = time*SPEED;
    for(float i = 0.; i<N; ++i){
        float w = W;
        float x = 2.*t-OFFSET/N*(i-TWIST*N)*sin(t*0.8);
        float y = 0.;
        float r = R*(i+0.6)/N;
        float d = dArc(r, x, x+w);
        y += d2y(E*d);
        
        x+=PI;
        d = dArc(r, x, x+w);
        y += d2y(E*d);
        
        y = pow(y,CONTRAST);
        rgb += y * hsv2rgb(vec3(i/N, SAT,1.0));
    }
    
    glFragColor = vec4(rgb, 1.0);

}
