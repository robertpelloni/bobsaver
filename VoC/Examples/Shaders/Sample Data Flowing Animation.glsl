#version 420

// original https://www.shadertoy.com/view/stSXDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)

float Hash21(vec2 p) {
    p = fract(p*vec2(234.56,789.34));
    p+=dot(p,p+34.56);
    return fract(p.x+p.y);
}

vec3 randomPlot(vec2 p, vec3 col, float t){
    p*=20.0;
    p.x+=t;
    vec2 gv = fract(p)-0.5;
    vec2 id = floor(p);
    gv.y = id.y;
    
    float n = Hash21(id);
    float w = clamp(0.25*(n*2.0),0.1,1.0);
    float d = B(gv,vec2(w,0.02));
    float cn = clamp(n,0.5,1.0);
    col = mix(col,vec3(cn,cn,cn),S(d,0.0));
    return col;
}

const float speeds[14] = float[](2., 3., 6., 3.5, 5., 7., 4.5, 7.5, 8.0, 9., 2.5, 6.5,10.0,5.3);
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0.0);
    
    float index = 0.07;
    for(int i = 0; i<14; i++){
        vec2 pos = uv+vec2(index,-0.5+(index));
        col = randomPlot(pos, col, time*speeds[i]);
        index+=0.07;
    }

    glFragColor = vec4(col,1.0);
}
