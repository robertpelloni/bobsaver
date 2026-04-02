#version 420

// original https://www.shadertoy.com/view/WsscRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 randompoint( in float anim, in float n )
{
    vec2 ab = vec2(sin(anim*0.01+n*n)+sin(anim*0.039)+cos(anim*0.0071),
                   cos(anim*0.011+n/17.0)+sin(anim*0.036+n*1.3)+cos(anim*0.0078));
    return vec2(1.25*sin(n*1.7+ab.x), cos(n+ab.y));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy - 0.5*resolution.xy;
    uv = 2.0*uv/resolution.y;
    
    float r =  length(uv - randompoint(time,  0.0));
    r = min(r, length(uv - randompoint(time,  1.0)));
    r = min(r, length(uv - randompoint(time,  2.0)));
    r = min(r, length(uv - randompoint(time,  3.0)));
    r = min(r, length(uv - randompoint(time,  4.0)));
    r = min(r, length(uv - randompoint(time,  5.0)));
    r = min(r, length(uv - randompoint(time,  6.0)));
    r = min(r, length(uv - randompoint(time,  7.0)));
    r = min(r, length(uv - randompoint(time,  8.0)));
    r = min(r, length(uv - randompoint(time,  9.0)));
    r = min(r, length(uv - randompoint(time, 10.0)));
    
    float width = 6.0 / 200.0;
    r = mod(r,width)/width;
    r = 2.0*abs(r-0.5);
    r = clamp(r, 0.25, 0.75);
    r = ((r - 0.5) / 0.25) + 0.5;
    vec3 col = clamp( r, 0.0, 1.0)*vec3(1,1,1);  
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
