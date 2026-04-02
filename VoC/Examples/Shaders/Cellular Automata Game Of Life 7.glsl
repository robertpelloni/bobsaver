#version 420

// original https://www.shadertoy.com/view/4dtSzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define brushSize 40.0

#define survive n > 1 && n < 4
#define birth n == 3

#define U(p) ((gl_FragCoord.xy+p)/resolution.xy)
#define P(p) texture2D(backbuffer, U(p))
#define C(v) (int(ceil(P(v).x)))
#define N(r) for(float i=.0;i<8.;i++) { n+=C(vec2(floor(cos(i*r)+.5),floor(sin(i*r)+.5))); }
#define z2 vec2(.0)
#define z4 vec4(.0)
#define o4 vec4(1.)

//noise see https://www.shadertoy.com/view/ltB3zD
float snoise(in vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    
    float d = .002;
    vec4 c = P(z2) - vec4(d * 1.2, d * .5, d, .0);
    
    int n = 0;
    N(.7853981633);
    if(time > 0.1)
    {
        if(distance(mouse*resolution.xy.xy, gl_FragCoord.xy) < brushSize )
            glFragColor = o4;
        else
            glFragColor = C(z2) == 0 ? (birth ? o4 : z4) : (survive ? c : z4);
    }
    else
    {
        glFragColor = vec4(snoise(gl_FragCoord.xy) > 0.8 ? 1.0 : 0.0);
    }
            
    

}
