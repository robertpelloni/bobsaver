#version 420

// original https://www.shadertoy.com/view/wlSfRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float field(vec2 uv)
{
    float o = 1.;
    for (float dot = 0.; dot < 40.; dot+=1.) {
        vec2 center = vec2(.1+sin(time*.01+3e2+dot), sin(time*.02+2e2+dot*1.2))*.5+.5;
        float r = .02;
        o *= smoothstep(0.,.1, length(uv-center)-r);
    }
    return o;
}

vec2 gradient(vec2 uv, float f)
{
    vec2 ep = vec2(.001, 0.);
    return vec2(field(uv + ep.xy) - f, field(uv + ep.yx) - f) / ep.x;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.y *= resolution.y / resolution.x;

       float f = field(uv);
    vec2 grad = gradient(uv, f);
    float angle = atan(grad.x, grad.y);
   
    f -= dot(grad, grad)*pow(2.-sin(angle*16.-time*9.),3.)*4e-5;
    
    vec4 O = vec4(vec3(f), 1.);    
    O.g = sin(O.g*10.);
    O.r = smoothstep(0.1, 0.6, O.r);
    O.g = smoothstep(0.2, 0.7, O.g);
    O.b = smoothstep(0.3, 0.8, O.b);

    glFragColor = O;
}
