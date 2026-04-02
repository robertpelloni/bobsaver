#version 420

// original https://www.shadertoy.com/view/td2fDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define COUNT 50.
#define COL_BLACK vec3(23,32,38) / 255.0 

#define SF 1./min(resolution.x,resolution.y)
#define SS(l,s) smoothstep(SF,-SF,l-s)
#define hue(h) clamp( abs( fract(h + vec4(3,2,1,0)/3.) * 6. - 3.) -1. , 0., 1.)

void main(void)
{
    
    vec2 uv = gl_FragCoord.xy/resolution.y;
    
    float m = 0.;
    float t = time *.5;
    vec3 col;
    for(float i=COUNT; i>=0.; i-=1.){        
        float edge = -.1 + i*.025 + sin(time + uv.x*10. + i*100.)*.1 + cos(time + uv.x*2.5 + i*100.)*.1;
        float mi = SS(edge, uv.y - 1.) - SS(edge + .0025, uv.y);        
        m *= SS(edge, uv.y+.01);
        m += mi;        
        
        if(mi > 0.){
            col = hue(i/COUNT).rgb;
        }        
    }           
    
    col = mix(COL_BLACK, col, m);
    
    glFragColor = vec4(col,1.0);
}
