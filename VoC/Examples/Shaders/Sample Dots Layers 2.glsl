#version 420

// original https://www.shadertoy.com/view/WlB3RW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LAYERS_COUNT 25.

#define BLACK_COL vec3(16,22,26)/255.

#define rand1(p) fract(sin(p* 78.233)* 43758.5453) 
#define hue(h) clamp( abs( fract(h + vec4(3,2,1,0)/3.) * 6. - 3.) -1. , 0., 1.)

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;    
    uv += vec2(sin(time),cos(time))*.2;
    
    float t = time*.125;          
        
    vec3 col = vec3(0.);
    float s = 0.;
    
    float bStep = 1./LAYERS_COUNT; 
    for(float n=0.; n< LAYERS_COUNT; n+=1.){        
        float sx = fract(t + bStep*n);
        vec2 guv = uv * ((1. - sx) * 50.);     
        vec2 gid = floor(guv);
        guv = fract(guv) - .5;

        float sz = (max(sx, .5) - .5);
        float b1 = .05 + sz * .5;        
        float b2 = b1-.02;       
        float l = length(guv);
        float si = smoothstep(b1, b2, l) - smoothstep(b1-.1, b2-.1, l);           
        float six = si* sx;
        
        col += hue(rand1(gid.x+gid.y*100. + n)).rgb * six;
        
        s += six;
    }
    
    col = mix(BLACK_COL, col, s);    
    glFragColor = vec4(col,1.0);
}
