#version 420

// original https://www.shadertoy.com/view/tl2cRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time

#define MAX_STEPS 200
#define MAX_DIST 200.0
#define SURFACE_DIST 0.01
#define DEFAULT_SHADOW_ATT 0.5
#define PROCESSED_LIGHTS 3
#define AMBIENT_INTENSITY 0.2

struct DistanceInfo {
    float dist; // Distance to object
    int id; // Object ID
};

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k*h * (1.0 - h);
}

vec2 gooBall(vec3 rp, vec3 frontPos, vec3 backPos, float radius, float fn) {
    vec2 ret;
    // Front ball
    ret.x = length(rp - frontPos)
        - radius - sin(rp.x * 5.0 + t*10.0) * 0.05 + sin(rp.y * 5.0 - t*1.0) * 0.01;
    
    // Back ball
    ret.y = length(rp - backPos)      
       - radius - sin(rp.x * 5.0 + t*10.0) * 0.05 + sin(rp.y * 1.0 - t*1.0) * 0.01;
    return ret;
}

DistanceInfo map(vec3 rp)
{
    float ret;
    float s[3];

    // Gooball
    float phase = -1.8;
    float freq = 0.8;
    float amp = 0.9;
    float heigth = 1.0;
    vec3 frontPos = vec3(0., sin(t * freq + phase) * (5. * amp) + heigth, 0.);
    vec3 backPos = vec3(-1.7 + sin(t) * 1., sin(t * freq - .2 + phase) * (5. * amp) + heigth,0.);
    vec2 gb = gooBall(rp, frontPos, backPos, 2., 0.);
    s[0] = gb.x;
    s[1] = gb.y;

    // Plane
    float plane = rp.y + sin(rp.x+t*8.)*0.15; //+ sin(rp.x + t*10.) * 0.2;

    // Combine maps and set material data    
    float dist = 1.0;
    for(int i=0; i<2; i++){
        dist = smin(dist, s[i], 0.45);
    }
    dist = smin(dist, plane,0.45);
    
    int id = 10;
    return DistanceInfo(dist, id);
}

DistanceInfo march(vec3 ro, vec3 rd)
{
    vec3 color;
    float md; // Marched distance
    DistanceInfo di;
    for(int i = 0; i < MAX_STEPS; i ++ ) {
        vec3 rp = ro + rd * md + -0.71;
        di = map(rp);
        md += di.dist;
        if (md > MAX_DIST || di.dist < SURFACE_DIST)break;
    }
    return DistanceInfo(md, di.id);
}

vec3 getNormal(vec3 p) {
    float d = map(p).dist; // Get distance to surface point
    
    // Normal trick from Art Of Code (using derivatives/slopes)
    vec2 e = vec2(0.01, 0);
    vec3 n = d-vec3(map(p - e.xyy).dist, map(p - e.yxy).dist, map(p - e.yyx).dist);
    
    return normalize(n); // Return unit vector because we want a direction
}

struct LightOutput {
    float diffuse;
    float specular;
    float attenuation; // Used for shadows
};

struct LightData {
    vec3 position;
    float intensity;
};

LightOutput light(vec3 ro, vec3 p, vec3 normal, LightData data) {
    // Phong based
    vec3 lv = normalize(data.position - p); // Get light vector at that point (light pos - surface pos)
    float diffuse = max(dot(normal, lv), 0.0);
    
    // Specular
    vec3 viewVector = normalize(p - ro);
    vec3 lr = reflect(lv, normal);
    float specular = smoothstep(0.,0.31,pow(max(dot(viewVector, lr), 0.0), 50.0)); // Calculate specular brigthness
        
    // Shadow (from Art Of Code)
    float attenuation;
    vec3 sv = vec3(p.x+0.00,p.y + 0.00,p.z+0.00);
    float sd = march(sv + normal * SURFACE_DIST * 2.0, lv).dist;

    return LightOutput(diffuse * data.intensity, specular * data.intensity, attenuation);
}

vec3 shade(vec3 rd, vec3 ro, DistanceInfo di) {
    
    vec3 p = ro + rd * di.dist; // Get point to surfaces
    vec3 n = getNormal(p); // Get surface normal for point
    
    vec3 lightPos = vec3(1.35, 6.00, - -3.58 + sin(t * 0.5));
    
    LightOutput lights[3];
    lights[0] = light(ro, p, n, LightData(lightPos, 0.7));
    lights[1] = light(ro, p, n, LightData(lightPos + vec3(-18.85), 0.1));
    lights[2] = light(ro, p, n, LightData(lightPos + vec3(55.00,0.00,64.00), 0.5));
    
    // Ambient color
    vec3 ambient = vec3(AMBIENT_INTENSITY, AMBIENT_INTENSITY, AMBIENT_INTENSITY+0.34);
    
    // Object color
    vec3 color = vec3(0.8196, 0.2353, 0.2353);
    
    if (di.id != -1) { // If we hit something, calculate color
        float diffuse;
        float specular;
        float attenuation;
        
        // Accumulate lighting intensities from every light
        for(int i = 0; i < PROCESSED_LIGHTS; i ++ ) {
            diffuse += lights[i].diffuse;
            specular += lights[i].specular;
            attenuation += lights[i].attenuation;
        }
        
        vec3 litColor = (ambient + diffuse) * color + specular;
        
        return litColor * (1.-attenuation);
        
    }else { // Else, we are in the skybox/background
        return vec3(0);
    }
}

vec4 image(vec2 uv) 
{
    vec3 ro = vec3(-7.0, 6.35, -15.0); // Ray origin or camera position
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.00)) + vec3(0.8,-0.3,1.1);
    
    DistanceInfo di = march(ro, rd); // Get distance to scene objects
    vec3 col = shade(rd, ro, di); // Fragment color. Calculate shading.
    
    return vec4(col, 1.0); 
}

vec2 setupSpace(in vec2 f, in vec2 res)
{
    return (f.xy / res.xy - 0.5) *
    vec2(res.x / res.y, 1.0) * 2.0;
}

void main(void)
{
    vec2 uv = setupSpace(gl_FragCoord.xy, resolution.xy);
    glFragColor = image(uv);
}
