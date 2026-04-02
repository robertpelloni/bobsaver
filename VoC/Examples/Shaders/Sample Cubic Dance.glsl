#version 420

// original https://www.shadertoy.com/view/Wt2GRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PRIMARY_STEPS 32
#define SECONDARY_STEPS 16

#define RM_EPSILON 0.01
#define BIAS_EPSILON 0.02

#define MAX_DIST 30.

#define REFLECTIONS 1
#define SHADOWS 1

struct Light {
    vec3 dir;
    vec3 diffColor;
    vec3 specColor;
};

struct ScenePoint {
    vec3 p;
    vec3 color; //Color of material
    float d; //Distance to closest object
    float t; //Distance on ray that generated this point
};

Light lights[4];

float rand(float v) {
    return fract(sin(v) * 5454.7367);
}

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 4451.5453);
}

vec3 cam2world(vec3 v, vec3 pos, vec3 lookAt) {
    vec3 z = normalize(lookAt - pos);
    vec3 y = vec3(0., 1., 0.);
    vec3 x = normalize(cross(z, y));
    y = normalize(cross(x, z));
    return normalize(mat3(x, y, z) * v);
}

vec2 repeat(inout vec2 p, vec2 size) {
    vec2 h = size * .5;
    vec2 cell = floor((p + h) / size);
    p = mod(p + h, size) - h;
    return cell;
}

float roundBox(vec3 p, vec3 c, vec3 b, float r) {
    vec3 d = abs(p - c) - b;
    return length(max(d, 0.)) - r + min(max(d.x, max(d.y, d.z)), 0.);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1., 2. / 3., 1. / 3., 3.);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6. - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0., 1.), c.y);
}

float stoppingCurve(float t, float stopFactor) {
  return mix(rand(floor(t)), rand(floor(t) + 1.), pow(smoothstep(0., 1., fract(t)), stopFactor));
}

ScenePoint scene(vec3 p, int neighboursToCheck) {
    ScenePoint result;

    float dist = MAX_DIST;
    vec2 cellId;
    vec3 repP;

    for(int x = -neighboursToCheck; x <= neighboursToCheck; ++x) {
        for(int y = -neighboursToCheck; y <= neighboursToCheck; ++y) {
            vec3 currentRepP = p;
            vec2 currentCellId = repeat(currentRepP.xy, vec2(1.));

            vec2 offset = vec2(float(x), float(y));
            currentCellId += offset;

            currentRepP.xy -= offset; // * cellSize = 1.0

            float timeOffset1 = mod(currentCellId.x * currentCellId.y, 2.0);
            float timeOffset2 = mod(currentCellId.x + currentCellId.y, 2.0);
            float timeOffset3 = mod(currentCellId.x, 2.0);
            float timeOffset4 = mod(currentCellId.y, 2.0);
            float timeOffsetFinal = mix(mix(timeOffset1, timeOffset2, sin(time * .4 + 56.2) * .5 + .5),
                                        mix(timeOffset3, timeOffset4, sin(time * .5 + 12.5) * .5 + .5),
                                        sin(time * .6 + 23.4) * .5 + .5);

            currentRepP.z += stoppingCurve(1.7 * time + timeOffsetFinal, 5.) * 2.5;

            const float minSize = .31;
            const float maxSize = .43;
            float sizeAnim = stoppingCurve(0.9 * time + timeOffsetFinal, 5.) * (maxSize - minSize) + minSize;
            float currentCubeDist = roundBox(currentRepP, vec3(0.), vec3(sizeAnim), .07);
            if(currentCubeDist < dist) {
                dist = currentCubeDist;
                cellId = currentCellId;
                repP = currentRepP;
            }
        }
    }

    float wallX = (-cellId.x + 6.) / 13.;
    float cubeDiagonal = (repP.x + .5) * (repP.y + .5);

    vec3 cubeBaseHsv = vec3(wallX, 1., 1.);
    cubeBaseHsv.r += .1 * rand(cellId.y);

    vec3 cubeColor1 = hsv2rgb(cubeBaseHsv);
    vec3 cubeColor2 = hsv2rgb(vec3(cubeBaseHsv.r + .2 * rand(cellId.x), cubeBaseHsv.g, cubeBaseHsv.b));

    result.color = mix(cubeColor1, cubeColor2, cubeDiagonal);
    result.d = dist;
    return result;
}

bool rm(vec3 ro, vec3 rd, out ScenePoint sp, int steps, int neighboursToCheck) {
    float t = 0.;
    vec3 p;

    for(int i = 0; i < steps && t < MAX_DIST; ++i) {
        p = ro + rd * t;
        sp = scene(p, neighboursToCheck);
        if(sp.d < RM_EPSILON) {
            sp.p = p;
            sp.t = t;
            return true;
        }
        t += sp.d;
    }
    return false;
}

vec3 normal(ScenePoint sp) {
    vec2 e = vec2(RM_EPSILON, 0.);
    float x = scene(sp.p - e.xyy, 1).d;
    float y = scene(sp.p - e.yxy, 1).d;
    float z = scene(sp.p - e.yyx, 1).d;
    return normalize(vec3(sp.d) - vec3(x, y, z));
}

float cheapAo(vec3 p, vec3 n, float dist) {
    float d = scene(p + n * dist, 1).d / dist;
    return clamp(d, 0., 1.);
}

/*float ao(vec3 p, vec3 n, float strength) {
    const int AO_SAMPLES = 2;
    float k = 1.;
    float d = 0.;
    float occ = 0.;
    for(int i = 0; i < AO_SAMPLES; i++) {
        d = scene(p + .1 * k * n, 0).d;
        occ += 1. / pow(2., k) * (k * .1 - d);
        k += 1.;
    }
    return 1. - clamp(strength * occ, 0., 1.);
}*/

vec3 lighting(vec3 cameraPos, vec3 normal, ScenePoint sp) {
    vec3 albedo = sp.color;
    vec3 specular = vec3(1.);
    float shininess = 100.;

    vec3 V = normalize(cameraPos - sp.p);

    vec3 sum = vec3(0.);
    for(int i = 0; i < 4; ++i) {
        vec3 L = -lights[i].dir;
        vec3 H = normalize(V + L);

        float difFactor = max(0., dot(L, normal));
        float specFactor = pow(max(0., dot(H, normal)), shininess);
        sum += lights[i].diffColor * albedo * difFactor +
               lights[i].specColor * specular * specFactor;
    }
    return sum;
}

vec3 shadeAndReflection(vec3 cameraPos, vec3 rd, ScenePoint sp) {
    vec3 result;

    vec3 normal = normal(sp);
    vec3 light = lighting(cameraPos, normal, sp);
    float ao = cheapAo(sp.p, normal, .15);

    bool hit;
    result = light * ao;
    
#if REFLECTIONS
    ScenePoint reflectionSp;
    vec3 reflected = reflect(rd, normal);
    hit = rm(sp.p + reflected * BIAS_EPSILON, reflected, reflectionSp, SECONDARY_STEPS, 1);
    if(hit) {
        result = mix(light, lighting(cameraPos, reflected, reflectionSp), .5) * ao;
    }
#endif
    
#if SHADOWS
    ScenePoint shadowSp;
    hit = rm(sp.p + normal * BIAS_EPSILON, -lights[0].dir, shadowSp, SECONDARY_STEPS, 1);
    if(hit) {
        result *= vec3(.2);
    }
#endif
    
    return result;
}

void main(void) {
    lights[0].dir = normalize(vec3(0., -.3, -1.));
    lights[0].diffColor = vec3(1.);
    lights[0].specColor = vec3(1.);

    lights[1].dir = normalize(vec3(1., 0., 0.));
    lights[1].diffColor = vec3(.3);
    lights[1].specColor = vec3(.05);

    lights[2].dir = normalize(vec3(0., 1., 0.));
    lights[2].diffColor = vec3(.3);
    lights[2].specColor = vec3(.05);

    lights[3].dir = normalize(vec3(-1., 0., 0.));
    lights[3].diffColor = vec3(.3);
    lights[3].specColor = vec3(.05);

    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    float curve = stoppingCurve(time * .5 + 12., 5.);
    float curve2 = stoppingCurve(time * .8 + 195., 50.);

    vec3 cameraPos = vec3(6. * (curve - .5) + time, 1.9 * (curve2 + .5), 10.);
    vec3 lookAt = vec3(time, 0., 0.);
    vec3 rd = cam2world(vec3(uv, 1.), cameraPos, lookAt); 

    ScenePoint sp;
    vec3 col = vec3(.05);

    bool hit = rm(cameraPos, rd, sp, PRIMARY_STEPS, 1);
    if(hit) {
        col = shadeAndReflection(cameraPos, rd, sp);
    }

    col = pow(col, vec3(1. / 2.2));
    glFragColor = vec4(col, 1.);
}
