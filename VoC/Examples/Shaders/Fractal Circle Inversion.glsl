#version 420

// original https://www.shadertoy.com/view/MtK3W3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define L_SIDE_POS 150.0
#define S_SIDE_POS 42.4
#define L_SQR 22500.0
#define S_SQR 900.0

vec3 getInverse(vec2 p) {
    float theta = time;
    mat2 sideRotation = mat2(
        cos(theta), -sin(theta),
        sin(theta), cos(theta)
    );
    mat2 innerRotation = mat2(
        cos(-theta), -sin(-theta),
        sin(-theta), cos(-theta)
    );
    
    float sq_radii[8];
    sq_radii[0] = S_SQR;
    sq_radii[1] = L_SQR;
    sq_radii[2] = L_SQR;
    sq_radii[3] = L_SQR;
    sq_radii[4] = L_SQR;
    sq_radii[5] = S_SQR;
    sq_radii[6] = S_SQR;
    sq_radii[7] = S_SQR;

    vec2 centers[8];
    centers[0] = innerRotation*vec2(S_SIDE_POS, 0.0);
    centers[1] = sideRotation*vec2(-L_SIDE_POS,  L_SIDE_POS);
    centers[2] = sideRotation*vec2( L_SIDE_POS,  L_SIDE_POS);
    centers[3] = sideRotation*vec2(-L_SIDE_POS, -L_SIDE_POS);
    centers[4] = sideRotation*vec2( L_SIDE_POS, -L_SIDE_POS);
    centers[5] = innerRotation*vec2(-S_SIDE_POS, 0.0);
    centers[6] = innerRotation*vec2(0.0,  S_SIDE_POS);
    centers[7] = innerRotation*vec2(0.0, -S_SIDE_POS);
    
    float inside = 0.0;
    float insideSqRadius;
    vec2 insideCenter;
    for (int i = 0; i < 8; ++i) {
        vec2 pShift = p - centers[i];
        float sqMag = dot(pShift, pShift);
        float insideCurrent = 1.0 - step(0.0, sqMag - sq_radii[i]);
        inside += insideCurrent;
        if (insideCurrent > 0.0) {
            insideSqRadius = sq_radii[i];
            insideCenter = centers[i];
        }
    }
    
    if (inside > 0.0) {
        // perform inversion
        vec2 pShift = p - insideCenter;
        float mag = sqrt(dot(pShift, pShift));
        // sqR = magP*magP1
        float magP1 = insideSqRadius / mag;
        vec2 p1 = insideCenter + normalize(pShift)*magP1;
        return vec3(p1, inside);
    } else {
        return vec3(p, inside);
    }
}

// colormap functions from these guys:
// https://github.com/kbinani/glsl-colormap/blob/master/shaders/IDL_Green-White_Linear.frag
float colormap_red(float x) {
    return 1.61361058036781E+00 * x - 1.55391688559828E+02;
}

float colormap_green(float x) {
    return 9.99817607003891E-01 * x + 1.01544260700389E+00;
}

float colormap_blue(float x) {
    return 3.44167852062589E+00 * x - 6.19885917496444E+02;
}

vec4 colormap(float x) {
    float t = x * 255.0;
    float r = clamp(colormap_red(t) / 255.0, 0.0, 1.0);
    float g = clamp(colormap_green(t) / 255.0, 0.0, 1.0);
    float b = clamp(colormap_blue(t) / 255.0, 0.0, 1.0);
    return vec4(r, g, b, 1.0);
}

#define MAX_IT 10
void main(void)
{
    vec2 cCoord = gl_FragCoord.xy - resolution.xy*0.5;
    
     float steps = 0.0;
    for (int i = 0; i < MAX_IT; ++i) {
        vec3 res = getInverse(cCoord);
        steps += res.z;
        cCoord = res.xy;
    }
    
    vec4 c0 = vec4(0, 0, 0, 1);
    vec4 c1 = vec4(0, 1, 0, 1);
    steps /= float(MAX_IT);
    glFragColor = colormap(steps);
    
    // circle positions
    //float inside = getInverse(gl_FragCoord.xy - resolution.xy*0.5).z;
    //glFragColor = vec4(inside, inside, inside, 1.0);
}
