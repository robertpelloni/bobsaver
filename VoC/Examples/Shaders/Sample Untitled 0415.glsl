#version 420

#define PI 3.14159265359
#define TWO_PI 6.28318530718

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float impulse(float k, float x)
{
    float h = k*x;
    return h*exp(1.0-h);
}
void main( void ) {
    vec2 uv = gl_FragCoord.xy/resolution;
    vec3 color = vec3(.0);
    uv.x *= resolution.x/resolution.y;
    
    float d = .0;
    
    uv = uv*2. -1.;
    uv.x -= 1.;
    //int N = int(abs(sin(time/PI))*15.)+8;
    int N = 3;
    float a = atan(uv.x, uv.y)+PI +3.*sin(time);
    float r = TWO_PI/float(N);
    d = cos(floor(.5+a/r)*r-a)*length(uv);
    float pct =1.0-smoothstep(.4,.41,d);
    
    
    float a2 = atan(uv.x, uv.y)+PI -.8*impulse(5.,abs(fract(time)));
    float r2 = TWO_PI/float(N);
    
    float d2= cos(floor(.5+a2/r2)*r2-a2)*length(uv);
    
    float pct2 = 1.0-smoothstep(.5,.51,d2);
    
    int N3 = 5;
    float a3 = atan(uv.x, uv.y)+PI +time*3.2 ;
    float r3 = TWO_PI/float(N3);
    
    float d3= cos(floor(.5+a3/r3)*r3-a3)*length(uv);
    
    float pct3 = 1.0-smoothstep(.2+impulse(5.,abs(sin(fract(time+0.5))))/10.,.21+impulse(5.,abs(sin(fract(time+0.5))))/10.,d3);
    
    pct = pct2-pct;
    
    color = vec3(0.2,.9,impulse(4., sin(time)))*max(0.,pct)+vec3(0.8,.2,.6)*pct3;
    
    
    glFragColor = vec4(color,1.);    
}
