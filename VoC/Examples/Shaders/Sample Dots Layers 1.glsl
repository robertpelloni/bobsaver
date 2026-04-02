#version 420

// original https://www.shadertoy.com/view/tt2GRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LAYERS_COUNT 5.

#define BLACK_COL vec3(16,22,26)/255.
#define WHITE_COL vec3(245,248,250)/255.

float sinp(float v){
    return sin(v)*.5 + .5;
}
void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    
    float t = time*.1;
    
    float s = 0.;
    
    float bStep = 1./LAYERS_COUNT;
    for(float n=0.; n< LAYERS_COUNT; n+=1.){
        
        float a = time*.25 + 10. * n;
        float ca = cos(a);
        float sa = sin(a);
        mat2 rot = mat2(ca, -sa, sa, ca);
        
        vec2 iuv = uv * rot + n*.1;
        
        float sx = fract(t + bStep*n);
        vec2 guv = iuv * ((1. - sx) * 50.);        
        guv = fract(guv) - .5;

        float sz = (max(sx, .5) - .5);
        float b1 = .05 + sz * .5;        
        float b2 = .04 - sz * .2;
        // float si = smoothstep (b1, b2, abs(guv.x)) + smoothstep (b1, b2, abs(guv.y));
        float si = smoothstep(b1, b2, length(guv));
        
        s += si * sx;
    }
    
    vec3 col = mix(BLACK_COL, WHITE_COL, s);    
    glFragColor = vec4(col,1.0);
}
