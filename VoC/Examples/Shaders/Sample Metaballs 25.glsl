#version 420

// original https://www.shadertoy.com/view/ldtSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Metaball{
    vec2 pos;
    float r;
    vec3 col;
};

vec4 calcball( Metaball ball, vec2 uv)
{
    float dst = ball.r / (pow(abs(uv.x - ball.pos.x), 2.) + pow(abs(uv.y - ball.pos.y), 2.));
    return vec4(ball.col * dst, dst);
}

vec3 doballs( vec2 uv )
{
    Metaball mb1, mb2, mb3, mb4;
    mb1.pos = vec2(1.3, .55+.2*sin(time*.5)); mb1.r = .05; mb1.col = vec3(0., 1., 0.);
    mb2.pos = vec2(.6, .45); mb2.r = .02; mb2.col = vec3(0., .5, 1.);
    mb3.pos = vec2(.85, .65); mb3.r = .035; mb3.col = vec3(1., .2, 0.);
    mb4.pos = vec2(1.+.5*sin(time), .2); mb4.r = .02; mb4.col = vec3(1., 1., 0.);
    
    vec4 ball1 = calcball(mb1, uv);
    vec4 ball2 = calcball(mb2, uv);
    vec4 ball3 = calcball(mb3, uv);
    vec4 ball4 = calcball(mb4, uv);
    
    float res = ball1.a + ball2.a + ball3.a + ball4.a;
    float threshold = res >= 1.5 ? 1. : 0.;
    
    vec3 color = (ball1.rgb + ball2.rgb + ball3.rgb + ball4.rgb) / res;
    color *= threshold;
    color = clamp(color, 0., 1.);
    return color;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.yy;
    vec3 color = doballs(uv);

    #define ANTIALIAS 2

    #ifdef ANTIALIAS
    float uvs = .75 / resolution.y;
    color *= .5;
    color += doballs(vec2(uv.x + uvs, uv.y))*.125;
    color += doballs(vec2(uv.x - uvs, uv.y))*.125;
    color += doballs(vec2(uv.x, uv.y + uvs))*.125;
    color += doballs(vec2(uv.x, uv.y - uvs))*.125;
    
    #if ANTIALIAS == 2
      color *= .5;
    color += doballs(vec2(uv.x + uvs*.85, uv.y + uvs*.85))*.125;
    color += doballs(vec2(uv.x - uvs*.85, uv.y + uvs*.85))*.125;
    color += doballs(vec2(uv.x - uvs*.85, uv.y - uvs*.85))*.125;
    color += doballs(vec2(uv.x + uvs*.85, uv.y - uvs*.85))*.125;
    #endif
    #endif

    glFragColor = vec4(color, 1.);
}
