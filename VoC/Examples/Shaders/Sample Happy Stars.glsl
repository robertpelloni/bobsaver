#version 420

// original https://www.shadertoy.com/view/Mtl3D2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA_SIZE 4.0
#define pi 3.141592653589793

float star(vec2 uv) {
    float a = atan(uv.y,uv.x);
    float r = length(uv);
    float starR = 0.5+0.25*pow(sin(a*2.5+time), 2.0);
    return r < starR ? 1.0 : 0.0;
}

float pointyStar(vec2 uv, float r, float rotation) {
    float a = atan(uv.y,uv.x);
    float len = length(uv);
    float starR = r/0.75 * (0.5+0.25*(abs(mod(a*2.5+rotation, pi)/(0.5*pi)-1.0)));
    return len - starR;
}

float pointyStars(vec2 uv) {
    uv *= 5.0;
    float phase = floor(0.5*uv.x)-floor(0.5*uv.y)+time*3.14159;
    return pointyStar(mod(uv, vec2(2.0))-1.0, 0.5+0.25*sin(phase), 2.0*cos(1.0*phase));
}

void main(void)
{
    glFragColor = vec4(0.0);
    for (float x=0.0; x < AA_SIZE; x++) {
        for (float y=0.0; y < AA_SIZE; y++) {
            vec2 aspect = vec2(resolution.x/resolution.y, 1.0);
            vec2 uv = (gl_FragCoord.xy + vec2(x,y)/AA_SIZE) / resolution.xy;
            uv = (2.0 * uv - 1.0) * aspect;
            float starD = pointyStars(uv);
            vec4 stars = vec4(1.2-0.8*abs(sin(uv*3.0)),0.7+0.3*sin(time+3.0*uv.x*uv.y),1.0) * float(starD < 0.0);
            vec4 glow = vec4(0.0);
            if (starD > 0.07) {
                glow = vec4(1.0, 1.0, 0.5, 1.0)*max(0.0, step(0.0, 0.1-starD));
            }
            float a = -0.3;
            uv.y += cos(time+uv.x*8.0+uv.y)*0.025;
            vec2 ruv = mat2(cos(a), sin(a), -sin(a), cos(a)) * uv * (1.0+0.25*(uv.y+1.7));
            vec2 checkerBoard = 0.5+0.5*sign(pow(sin(ruv*8.0), vec2(20.0))-0.5);
            vec2 checkerBoard2 = 0.5+0.5*sign(pow(sin((ruv)*8.0), vec2(8.0))-0.5);
            float c0 = max(checkerBoard.x, checkerBoard.y);
            float c1 = max(checkerBoard2.x, checkerBoard2.y);
            vec4 ccol = mix(vec4(0.8, 0.2, 0.15, 1.0), vec4(0.1, 0.15, 0.25, 1.0), 1.0-c0);
            vec4 bg = mix(vec4(0.98,0.95,0.75,1.0), ccol, max(c0, c1))*float(starD > 0.07);
            bg = mix(bg, vec4(1.0, 0.78, 1.0,1.0), max(0.0, min(0.5, abs(1.5-(ruv.y*0.3+1.7)))));
            vec4 col = bg + stars + glow;
            glFragColor += col;
         }
    }
    glFragColor /= AA_SIZE * AA_SIZE;
}
