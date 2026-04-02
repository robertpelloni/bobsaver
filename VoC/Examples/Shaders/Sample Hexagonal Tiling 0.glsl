#version 420

// original https://www.shadertoy.com/view/flKfzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float HexDist(vec2 p) {
    p = abs(p);
    
    float d = dot(p, normalize(vec2(1., 1.73)));
    d = max(d, p.x);
    
    return d;
}

vec4 HexCoord(vec2 p) {
    vec2 r = vec2(1., 1.73);
    vec2 h = r*.5;
    
    vec2 a = mod(p, r)-h;
    vec2 b = mod(p-h, r)-h;
    vec2 c = dot(a,a) < dot(b,b) ? a : b;
    
    vec2 id = p - c;
    
    return vec4(.5-HexDist(c), atan(c.x, c.y), id);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    vec4 hex = HexCoord((uv * (44. + cos(10.+time/30.)*40.))+ vec2(35.+time, 42.+time/2.));

    col += smoothstep(0., .25 - sin(time/2. + hex.z*1.5 + (.5+hex.w*2.)*hex.z) + cos(time/3. + hex.z), hex.x);
    col.rg -= vec2(.5 + cos(time*3. + hex.x)/9., .5 + sin(time + hex.y)/5.);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
