#version 420

// original https://www.shadertoy.com/view/tslczj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = round(gl_FragCoord.xy / resolution.xy * 80.0)/20.0;
    vec4 x = sin(sin(time * 1.3) + uv.y * 1.5 * cos(time) + 90.*vec4(0,1,2,3.0025)) * 0.4 + 2.0 + 0.2 * sin(2.0 * time + uv.y);
    vec2 p1 = uv/2.0-vec2(cos(time*0.21)+0.8, sin(time*0.14)+0.2);
    vec2 p2 = uv/2.0-vec2(sin(time*0.4)+0.3, cos(time*0.6));
    vec2 p3 = uv/2.0-vec2(cos(time*0.3)+0.5, sin(time*0.11)+1.0);
    vec3 d = 12.0 * vec3(sqrt(p1.x*p1.x+p1.y*p1.y), sqrt(p2.x*p2.x+p2.y*p2.y), sqrt(p3.x*p3.x+p3.y*p3.y));
    float c = (sin(d.x) + sin(d.y) + sin(d.z))/3.0*(1.0-sin(4.9+uv.x*1.5));
    glFragColor = vec4(uv.x > x.x && uv.x < x.y ? x.y-x.x : c, uv.x > x.y && uv.x < x.z ? x.z-x.y : 0.0, uv.x > x.z && uv.x < x.w ? x.w-x.z : -c, 1.0);
}
