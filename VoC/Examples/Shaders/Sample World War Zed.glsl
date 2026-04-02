#version 420

// original https://www.shadertoy.com/view/3dBSz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 r2(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(s,c,-c,s);
}

float rnd(float r){
    return fract(sin(r * 768.67)*7684.98);
}

float sdCapsule( vec2 p, vec2 a, vec2 b, float r ){
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return smoothstep(.02, .01, length( pa - ba*h ) - r);
}

vec4 effect(vec2 uv){
    float n = 0.0;//texture(iChannel0, uv).x;
    vec2 id = floor(uv);
    float updown = rnd(id.y);
    updown = updown > .5 ? 1.0 : -1.0;
    uv.x += rnd(id.y)*time*3.*updown;
    id = floor(uv);
    vec2 ft = fract(uv)-.5;
    
    float grid = step(.49, ft.x) + step(.49, ft.y);
    
    ft *= r2(.5*sin(3.*time+rnd(id.x*id.y)*2.)+1.5);
    
    float eye = length((vec2(abs(ft.x), ft.y))-.2);//- .025;
    eye = smoothstep(.03,.02,eye);
    
    float rand = rnd(id.x+id.y);
    rand = rand < .5 ? -1.0 : 1.0;
    
    float line = sdCapsule(ft, vec2(-0.17, -.3),vec2(.17, -.3), .001);    
    float line2 = sdCapsule(ft, vec2(-0.11, -.18),vec2(.11, -.18), .001);
    float line3 = sdCapsule(ft, vec2(-0.11*rand, -.18),vec2(0., .15), .001);
    
    vec4 color = vec4((line+line2+line3+eye)); //+;  //;color;
    color.r += grid;
    return color;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    uv *= 1.0 + dot(uv,uv)*.125;
    uv.x+=sin(time/2.)*4.;
    uv.y+=cos(time/2.)*4.;

    uv *= 2.;
    
    vec4 color = vec4(0.0);
    color = effect(r2(.25*sin(time/2.)+1.6)*uv+sin(time));
    
    glFragColor = vec4(color); // vec4(id*.2, 0.0, 1.0)*eye;
}
