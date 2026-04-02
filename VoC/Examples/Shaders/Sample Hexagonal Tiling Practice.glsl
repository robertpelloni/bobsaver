#version 420

// original https://www.shadertoy.com/view/wst3z8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FACTOR 20.

float HexDist(vec2 p, vec2 id){
    float t = time;
    mat2 rot = mat2(cos(t-id.x/FACTOR), -sin(t), sin(t), cos(t-id.x/FACTOR));
    p*=rot*1.3;
    p = abs(p); // Copy over first quad into all
    float c = dot(p, normalize(vec2(1,1.73)));// Dot to get correct angle
    return max(c, p.x); // Find where the vert line and angled intersect
}

vec4 HexCoords(vec2 uv){
    vec2 rep = vec2(1, 1.73);
    vec2 h = rep*0.5;
    vec2 a = mod(uv, rep)-h;
    vec2 b = mod(uv-h, rep)-h;

    
    vec2 gv;
    if(length(a) < length(b))
        gv = a;
    else 
        gv = b;
    
    vec2 id = (uv-gv)+FACTOR;
    float y = 0.5-HexDist(gv, id);
    return vec4(gv.x, y, id.x, id.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0);
    
    uv *= FACTOR;
    vec4 hexC = HexCoords(uv);
    float t = mod(time, 2000.);
    col += smoothstep(0.05, 0.1, hexC.y*sin(hexC.w*hexC.z+t));
    col += smoothstep(0.2, 0.15, hexC.y);
    col += 0.5-smoothstep(0.15, 0.1, hexC.y);
    col *= (0.7+sin(((hexC.z)/3.)+time)*0.3)*vec3(0.4, 0.7, 1.0);
    col += vec3(0.3, 0.4, 0.8)*0.2;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
