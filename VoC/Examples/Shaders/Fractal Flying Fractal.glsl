#version 420

// original https://www.shadertoy.com/view/wtjXRR

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * inspired by http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/
*/
#define N 60
void main(void)
{
    vec2 v = (gl_FragCoord.xy - resolution.xy/2.0) / min(resolution.y,resolution.x) * 20.0;
    vec2 m = date.zw;
    m=vec2(cos(.914+time*0.009), sin(.9*time*0.019)); 
    float rsum = 0.0;
    float pi2 = 3.1415926535 * 2.0;
    float a = (m.x-.5)*pi2;
    float C = cos(a);
    float S = sin(a);
    vec2 xaxis=vec2(C, -S);
    vec2 yaxis=vec2(S, C);
    float maxcycle=0.0;
    vec2 shift = vec2( 0, 1.618);
    float zoom = 1.0 + m.y*8.0;
    for ( int i = 0; i < N; i++ ){
        float rr = dot(v,v);
        if ( rr > 0.618 ){
            rr = 1.618/rr ;
            v.x = v.x * rr;
            v.y = v.y * rr;
        }
        if(rr > rsum)
        {
            rsum = rr;
            maxcycle = float(i);
        }

        v = vec2( dot(v,xaxis), dot(v,yaxis)) * zoom + shift;
    }
    
    float col = rsum/2.618;
    col = .2 + 2.0 * min(col, 1.0-col);
    float red, green, blue;
    
    red = fract(cos(maxcycle));
    green = fract(cos(maxcycle*1.2));
    blue = fract(cos(maxcycle*1.5));
    
    glFragColor = vec4(vec3(red, green, blue)*col*col, 1.0);
}
