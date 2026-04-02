#version 420

// original https://www.shadertoy.com/view/3sVGWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy/2.)/resolution.y;
    uv = uv * (time);
    vec3 col = vec3(0);
    float t = time * 4.;;
    
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    float minradius = 0.05;
    float maxradius = 0.5;
    
    col = vec3(maxradius - minradius);
    col.x *= sin(t + id.x + id.y + 2.2);
    col.y *= sin(t + id.x + id.y + 4.4);
    col.z *= sin(t + id.x + id.y);
    col += maxradius + minradius;
    col /= 2.;
    for(int i = 0; i < 3; ++i)
    {
        col[i] = smoothstep(col[i], col[i]*.8, length(gv));
        col[i] *= (col[i] + 0.3 * maxradius)/maxradius/1.3;
    }
    glFragColor = vec4(col, 1.);
}
