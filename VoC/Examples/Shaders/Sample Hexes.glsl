#version 420

// original https://www.shadertoy.com/view/WtGSRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float HexDist(vec2 p){
    p = abs(p);
    
    float c = dot(p,normalize(vec2(1,2.236)));
    return max(c,p.x);
}

vec4 HexCoords(vec2 uv){
    vec2 r = vec2(1.,1.73);
    vec2 h = r*.5;
    vec2 a = mod(uv,r)-h;
    vec2 b = mod(uv-h,r)-h;
    
    vec2 gv;
    if(length(a)<length(b))
        gv = a;
    else
       gv = b;
    
    float x = atan(gv.x,gv.y);
    float y = .5-HexDist(gv);
    vec2 id = uv-gv;
    return vec4(x,y,id.x,id.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec4 col = vec4(0);
    
    uv *= 9.;
    
    vec4 hc = HexCoords(uv);
    
    float c = smoothstep(0.05,.06, hc.y*sin(hc.z*hc.w+time));
    
    col += c;

    glFragColor = vec4(col);
}
