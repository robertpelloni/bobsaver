#version 420

// original https://www.shadertoy.com/view/wdlSDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_TAU 6.283185

void main(void)
{
    // ROYGBIV
    const vec3 colours[7] = vec3[7](
        vec3(1., 0., 0.),
        vec3(1., .5, 0.),
        vec3(1., 1., 0.),
        vec3(0., 1., 0.),
        vec3(0., 0., 1.),
        vec3(.293, 0., .5),
        vec3(.578, 0., .824)
    );

    vec2 origin = vec2(.5, 0.);

    // Square coordinates
    float shortRes;
    if(resolution.x > resolution.y){
        shortRes = resolution.y;
        origin.x = origin.x * resolution.x / resolution.y;
    } else {
        shortRes = resolution.x;
        origin.y = origin.y * resolution.y / resolution.x;
    }
    vec2 uv = gl_FragCoord.xy / shortRes - origin.xy;
    float r = length(uv);
    float theta = atan(uv.x, uv.y) / M_TAU;

    float cycle = fract(time * .2);

    float radius = 2. * cycle;    
    float band = .06 * cycle;
    float innerRadius = radius - 7. * band;
        
    vec3 col = vec3(0.);
    if(r <= radius && r >= innerRadius){
        int bandIndex = int((r - innerRadius) / band);
        if(theta < cycle - .15 -.02 * float(bandIndex)){
            col = colours[bandIndex];
            col *= cycle;
        }
    }

    glFragColor = vec4(sqrt(col), 1.);
}
