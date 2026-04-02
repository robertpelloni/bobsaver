#version 420

// original https://www.shadertoy.com/view/Wt2GDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SF 1./min(resolution.x,resolution.y)
#define SS(l,s) smoothstep(SF,-SF,l-s)
#define BLACK_COL vec3(16,21,25)/255.

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    float m = 0.;
    float t = time*2.;
    for(float i = 0.; i< 30.;i+=1.){
        float sv = sin(uv.x*10. + cos(t+i*.4))*.1;
        float y = uv.y + i*.025 - .15;
        m += (SS(y, sv) - SS(y + .001 * (0. + i*.5), sv)*.975)*(.75+i*.01) ;
    }
           
    vec3 col = mix(BLACK_COL, (0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4))), m);
    
    glFragColor = vec4(col,1.0);
}
