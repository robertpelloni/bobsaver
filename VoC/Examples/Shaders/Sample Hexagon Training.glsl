#version 420

// original https://www.shadertoy.com/view/3dVGD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float HexDist(vec2 p) {

    p = abs(p);
    
    float c = dot(p, normalize(vec2(1,1.73)));
    
    c = max(c, p.x); 
    
    return c;

}

vec4 HexCoords(vec2 uv) {

    vec2 r = vec2(1, 1.73);
    vec2 h = r*.5;
    
    vec2 a = mod(uv,r)-h;
    vec2 b = mod(uv-h,r)-h;
    
    vec2 gv = length(a)<length(b)? a : b;
    
    float x = atan(gv.x, gv.y);
    float y = .5-HexDist(gv);
    vec2 id = uv-gv;
    
    return vec4(x, y, id.xy);
}

void main(void)
{
   
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    // Time varying pixel color
    vec3 col = vec3(0);
  
    uv *= 10.;
   
        
    vec4 hc =  HexCoords(uv+100.);
    
    float c =  smoothstep(.01, .03, hc.y*sin(hc.z*hc.w+time));
    
    col += c; 
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
