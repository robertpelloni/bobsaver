#version 420

// original https://www.shadertoy.com/view/XsVSDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hex( vec2 p, float h )
{
    vec2 q = abs(p);
    return max((q.x*0.866025+q.y*0.5),q.y)-h;
}
vec3 sample2()
{
    vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    uv.y /= resolution.x / resolution.y;
    uv *= 0.01;
    uv /= exp(mod(time,3.52));
    float t = time*0.3;
    uv = vec2(sin(t)*uv.y + cos(t)*uv.x, -sin(t)*uv.x + cos(t)*uv.y);
    uv += sqrt(2.0);
    vec4 orb = vec4(1.0,100.0,100.0,0.0);
    for(int i = 0; i < 13; i++) {
        uv = abs(uv-1.0);
        float norm =  dot(uv,uv);
        uv = abs(uv/norm-1.0);
        uv = mod((abs(uv-0.5)+abs(-(uv-0.5)))*0.5, 1.0)*2.0;
        orb.x = min(orb.x, hex(uv, 0.3));
        orb.y = min(orb.y, uv.x);
        orb.z = min(orb.z, uv.y);
        orb.w += max(orb.z, uv.x);
    }
    return vec3(1.0-step(0.0, orb.x))+mod(time/3.52, 1.0)*0.1;

}
void main(void)
{
    vec3 col = sample2();
    glFragColor = vec4(col, 1.0);
}
