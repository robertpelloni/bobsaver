#version 420

// original https://www.shadertoy.com/view/WdVSRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ANGLES 6.
#define HEX_SIZE .7
#define AA (2./resolution.y)
#define EDGE_LENGTH .8
#define DOT_RAD .015
#define DOTS_COUNT 7.
#define DOT_STEP (EDGE_LENGTH/DOTS_COUNT)
#define HALF_DOT_STEP (DOT_STEP * .5)
#define r(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define THICKNESS .0005

const float PI = acos(-1.);
const float TAU = 2. * PI;
const float angDiff = PI/3.;

const vec3 CLR_BG = vec3(23., 19., 16.)/255.;
const vec3 CLR_TRAJ = vec3(36., 32., 29.)/255.;

float hexDistance(in vec2 p){
    p = abs(p);
    float h = dot(p, normalize(vec2(1., 1.73)));
    return max(h, p.x);
}

vec3 hsv2rgb(vec3 c) {
  // Íñigo Quílez
  // https://www.shadertoy.com/view/MsS3Wc
  vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);
  rgb = rgb * rgb * (3. - 2. * rgb);
  return c.z * mix(vec3(1.), rgb, c.y);
}

vec4 pattern(vec2 uv, float variant){
    float hex = hexDistance(uv);
    float traj = smoothstep(THICKNESS + AA, THICKNESS, abs(hex - HEX_SIZE));
    for(float i=0.; i<6.; i++){
        vec2 cntr = vec2(-EDGE_LENGTH, 0.) * r(i*angDiff + angDiff/2.);    
        float dst = distance(uv, cntr);
        traj = max(traj, step(dst, EDGE_LENGTH + THICKNESS + AA)
                       * step(hex, HEX_SIZE)
                       * smoothstep(HALF_DOT_STEP - THICKNESS - AA, HALF_DOT_STEP - THICKNESS,
                                    distance(HALF_DOT_STEP, mod(dst, DOT_STEP))));
    }
    vec4 bg = vec4(CLR_TRAJ, traj);
    
    float animationPhase = time;
    float sgmnt = mod(floor(animationPhase), 6.);
    float curAng = sgmnt * PI/3. + angDiff/2.;
    vec2 sp = vec2(-EDGE_LENGTH, 0.) * r(-curAng);
    float rotPhase = pow(fract(animationPhase), variant);
    vec2 dir = vec2(-1., 0.)
             * r(-(sgmnt - 1.) * PI/3. + angDiff/2.)
             * r(rotPhase * PI*2./3.);
    float index = floor((distance(sp, uv) + HALF_DOT_STEP)/DOT_STEP) * DOT_STEP;
    float point = step(distance(sp, uv), EDGE_LENGTH + DOT_RAD * 2.)
               * smoothstep(DOT_RAD + AA, DOT_RAD, distance(sp + dir * index, uv));
    {
        vec2 modDir = dir * r(curAng);
        vec2 st = normalize(uv - sp) * r(curAng);
        float pointAng = atan(modDir.y, modDir.x)/TAU+.5;
        float posAng = atan(st.y, st.x)/TAU+.5;
        float dst = step(posAng, pointAng)
                  * smoothstep((pow(fract(animationPhase), 4.) + .1) * smoothstep(.45, 0., abs(fract(animationPhase) - .5)), 0., abs(pointAng - posAng));
        bg = mix(bg, vec4(hsv2rgb(vec3(index + fract(animationPhase) * .5 + dst * .1 + 0.65, 1., 1.)), 1.), dst * step(hex, HEX_SIZE) * step(distance(sp, uv), EDGE_LENGTH + DOT_RAD * 2.) * smoothstep(DOT_RAD * dst * .5 + AA, DOT_RAD * dst * .5, distance(index, distance(sp, uv))));
    }
    
    return mix(bg, vec4(1.), point);
}

void main(void) {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy)/resolution.y;
    vec4 ptrn = pattern(uv - vec2(.9, 0.), 1.);
    glFragColor = vec4(mix(CLR_BG, ptrn.rgb, ptrn.a), 1.);
    ptrn = pattern(uv + vec2(.9, 0.), 4.);
    glFragColor.rgb = mix(glFragColor.rgb, ptrn.rgb, ptrn.a);
}
