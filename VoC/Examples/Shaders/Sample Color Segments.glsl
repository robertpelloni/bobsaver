#version 420

// original https://www.shadertoy.com/view/tlXGWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rand1(p) fract(sin(p* 78.233)* 43758.5453) 
#define hue(h) clamp( abs( fract(h + vec4(3,2,1,0)/3.) * 6. - 3.) -1. , 0., 1.)

#define SF 1./min(resolution.x,resolution.y)

float remap(float v, float oMin, float oMax, float rMin, float rMax){
    float result = (v - oMin)/(oMax - oMin);
    result = (rMax - rMin) * result + rMin;
    return result;
}

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    vec2 mult = vec2(30., 5.); // blocks aspect ratio
    vec2 guv = uv*mult;
    vec2 id = floor(guv);
    
    float t = time + 100.;
    float pS = remap(rand1(id.x), 0., 1., 0.8, 1.0); // prepare offset speed
    guv.y += pS * t; // make offset
    id = floor(guv); // update ID after offset
    guv = fract(guv);
    
    vec2 sf = mult * SF;
            
    vec2 bw = vec2(.5) - mult/250.; // border width
        
    float m = smoothstep(bw.x, bw.x - sf.x, abs(guv.x - .5)) * smoothstep(bw.y, bw.y - sf.y, abs(guv.y - .5));    
    
    vec3 col = hue(rand1(id.x + id.y)).rgb * m;      
    
    glFragColor = vec4(col,1.0);
}
