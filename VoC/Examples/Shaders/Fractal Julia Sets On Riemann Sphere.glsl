#version 420

// original https://www.shadertoy.com/view/WslBWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 256
#define HIT_THRESHOLD 0.00001

struct Surface {
    vec3 color;
};

    
struct SceneDistance {
    float d;
    Surface surface;
};
    
    

SceneDistance planeDist(Surface surface, vec3 p, vec3 n, float d) {
    return SceneDistance(
        dot(p, n.xyz) + d,
        surface
    );
}

SceneDistance sphereDist(Surface surface, vec3 p, float s) {
    return SceneDistance(
        length(p) - s,
        surface
    );
}

SceneDistance distanceUnion(SceneDistance d1, SceneDistance d2) {
    if (d1.d < d2.d) {
        return d1;
    }
    return d2;
}

SceneDistance distanceSubtract(SceneDistance d1, SceneDistance d2) {
    if (d2.d > -d1.d) {
        return d2;   
    }
    return SceneDistance(
        -d1.d, d2.surface    
    );
}

vec3 translate(vec3 v, vec3 t) {
    return v - t;
}

vec3 rotate(vec3 point, vec3 axis, float angle){
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    mat4 rot= mat4(
        oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,  0.0,
        oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,oc * axis.y * axis.z - axis.x * s,  0.0,
        oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
        0.0, 0.0, 0.0, 1.0);
    return (rot * vec4(point, 1.)).xyz;
}

SceneDistance scene(in vec3 pos) {
    Surface surf = Surface(vec3(0., 0., 1.));
    return  sphereDist(
        surf, translate( pos, vec3(0., 0., 0.)), 1. ); 
}

vec3 sceneNormal(vec3 pos, float d) {
    float eps = 0.001;
    vec3 n;
    
    n.x = scene(vec3( pos.x + eps, pos.y, pos.z )).d - d;
    n.y = scene(vec3( pos.x, pos.y + eps, pos.z )).d - d;
    n.z = scene(vec3( pos.x, pos.y, pos.z + eps )).d - d;
    
    return normalize(n);
}

struct Ray {
    vec3 org;
    vec3 dir;
};

struct MarchResult {
    bool hit;
    vec3 pos;
    vec3 norm;
    int steps;
    Surface surface;
};

MarchResult rayMarch(Ray ray) {
    MarchResult result = MarchResult(
        false,
        ray.org,
        vec3(0., 0., 0.),
        0,
        Surface(vec3(0., 0., 0.))
    );

    for (; result.steps < MAX_STEPS; result.steps++) {
        SceneDistance sd = scene(result.pos);
        if (sd.d < HIT_THRESHOLD) {
            result.hit = true;
            result.norm = sceneNormal(result.pos, sd.d);
            result.surface = sd.surface;
            break;
        }
        result.pos += sd.d * ray.dir;
    }
    return result;
}

float shadow(vec3 ro, vec3 rd, float mint, float maxt) {
    float t = mint;
    for ( int i = 0; i < 64; ++i )
    {
        float h = scene(ro + rd * t).d;
        if ( h < 0.001 && i > 0) {
            return 0.2;
        }
        t += h;
        
        if ( t > maxt )
            break;
    }
    return 1.0;
}

vec3 gradient(in float r) {    
    r /= 20.;
    r = clamp(r, 0.01, 1.);
    float mask = smoothstep(0., 0.2, r);
    r = pow(r, 0.4);
    vec3 rainbow = 0.5 + 0.5 * cos((5.5 * r + vec3(0.2, 0.45, 0.8)*6.));
    
    return rainbow * mask;
}

vec4 fractal(vec2 z, vec2 c) {    
    for (float i = 0.; i < 256.; ++i) {
                
        z = vec2(
            z.x*z.x - z.y*z.y + c.x,
            2.0 * z.x*z.y + c.y
        );
        

        float distSqr = dot(z, z);
        
        if (distSqr > 16.0)
            return vec4(gradient(float(i) + 1.0 - log2(log(distSqr) / 2.0)), 1.);
    }
    
    return vec4(0.0, 0.0, 0.0, 1.0);
}

vec3 colorSphere(in vec3 p) {
    vec2 pp = p.xz / (1. - p.y);
    pp.x -= 0.25;
    
    float scale = 20.;
    pp *= scale;
    vec2 c = round(pp);
    vec2 z = pp - c;
    c /= scale;
    c *= 3.;
    z /= scale;
    z *= 60. - 50. * (
        smoothstep(0., 10., mod(time, 20.))
        -smoothstep(10., 20., mod(time, 20.))
     );
    
    return fractal(z, c).rgb;
}

vec3 shade(MarchResult marchResult, vec4 light) {
    vec3 toLight = light.xyz - marchResult.pos;
    
    float toLightLen = length(toLight);
    toLight = normalize(toLight);
    
    float comb = 0.4;
       float vis = shadow(marchResult.pos, toLight, 0.01, toLightLen);
    if (vis > 0.0) {
        float diff = 1.2 * max(0.0, dot(marchResult.norm, toLight));
        float attn = 1.0 - pow(min(1.0, toLightLen / light.w), 2.0);
        comb += diff * attn * vis;
    }
    return comb * colorSphere(normalize(marchResult.pos));
}

void main(void) {
    vec2 ndcXY = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    float aspectRatio = resolution.x / resolution.y;
    vec2 scaledXY = 0.7 * ndcXY * vec2( aspectRatio, 1.0 );
    
    // camera XYZ in world space
    vec3 camWsXYZ = vec3(0.0, 0.0, 2.0);
       
    Ray ray;
    ray.org = camWsXYZ;
    ray.dir =  normalize(vec3( scaledXY, -1 ));
    float t = time / 20.;
    float ph = 0. + 6.28 * t;
    float th = -1.57 - 0.3 * sin(6.28 * t);
    ray.org = rotate(ray.org, vec3(1., 0., 0.), th);
    ray.dir = rotate(ray.dir, vec3(1., 0., 0.), th);
    ray.org = rotate(ray.org, vec3(0., 1., 0.), ph);
    ray.dir = rotate(ray.dir, vec3(0., 1., 0.), ph);
    
    
    // define point lights (XYZ, range)
    vec4 light = vec4(0.0, -2., 0.5, 8.0);
    
    MarchResult marchResult = rayMarch(ray);
    
    if (marchResult.hit) {
        vec3 shade = shade(marchResult, light);
        
        glFragColor = vec4(shade, 1.0);
    }
    else {
        glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    
    
    
}
