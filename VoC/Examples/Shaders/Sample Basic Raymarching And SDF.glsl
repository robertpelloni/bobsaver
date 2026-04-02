#version 420

// original https://www.shadertoy.com/view/7dGXRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURFACE_DIST .01

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float ssub( float d1, float d2, float k ) { 
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 ); 
    return mix( d2, -d1, h ) + k*h*(1.0-h);
} 

float sphereSDF(vec3 p, vec4 sphere) {
    return length(p - sphere.xyz) - sphere.w;
}

float planeSDF(vec3 p, vec3 pos, vec3 normal) {
    return dot(p - pos, normal);
}

//----Model 1----//
float Object1(vec3 p) {
    vec4 sphere = vec4(-2, 2, 5, 1);
    sphere.y += 4. * sin(time);
    vec4 sphere2 = vec4(2, 2, 5, 0.75);
    sphere2.y += 2.5 * sin(time);
    vec4 sphere3 = vec4(2, 2, 5, 0.5);
    sphere3.y += 2.5 * sin(time);
    vec3 planePos1 = vec3(0, 0, 0);
    vec3 planeNormal1 = normalize(vec3(0, 1, 0));
    vec3 planePos2 = vec3(0, 4, 0);
    vec3 planeNormal2 = normalize(vec3(0, -1, 0));
    float space = ssub(sphereSDF(p, sphere2)
    , min(planeSDF(p, planePos1, planeNormal1), planeSDF(p, planePos2, planeNormal2))
    , 0.5);
    
    return min(smin(sphereSDF(p, sphere), space, 0.75), sphereSDF(p, sphere3));
}
float RayMarching1(vec3 ro, vec3 rd) {
    float dO = 0.;
    for (int i = 0; i < MAX_STEPS; i ++) {
        vec3 P = ro + dO * rd;
        float ds = Object1(P);
        dO += ds;
        if (ds < SURFACE_DIST || dO > MAX_DIST) break;
    }
    return dO;
}
vec3 ObjectNormal1(vec3 p) {
    float d = Object1(p);
    vec2 e = vec2(0.01, 0.0);
    
    vec3 n = d - vec3(
        Object1(p - e.xyy),
        Object1(p - e.yxy),
        Object1(p - e.yyx)
    );
    return normalize(n);
}
vec3 ObjectLight1(vec3 p, vec3 rd) {
    
    vec3 lightPos1 = vec3(0, 1, 5);
    lightPos1.xz += 2.0 * vec2(sin(time + 3.14), cos(time + 3.14));
    vec3 lightDir1 = normalize(lightPos1 - p);
    vec3 lightCol1 = vec3(0.7, 0, 0.0);
    
    vec3 normal = ObjectNormal1(p);
    
    vec3 ambient = vec3(0.1, 0.1, 0.1);
    
    vec3 diffuse1 = lightCol1 * clamp(dot(lightDir1, normal), 0.0, 1.0);
    vec3 specular1 = vec3(pow(clamp(dot((lightDir1 - rd) / 2.0, normal), 0., 1.), 32.0));
    
    if (RayMarching1(p + normal * SURFACE_DIST * 1.75, lightDir1) < length(lightPos1 - p)) {
        diffuse1 *= 0.5;
        specular1 *= 0.0;
    }
    
    vec3 lightPos2 = vec3(0, 1, 5);
    lightPos2.xz += 2.0 * vec2(sin(time), cos(time));
    vec3 lightDir2 = normalize(lightPos2 - p);
    vec3 lightCol2 = vec3(0.0, 0, 0.7);
    
    vec3 diffuse2 = lightCol2 * clamp(dot(lightDir2, normal), 0.0, 1.0);
    vec3 specular2 = vec3(pow(clamp(dot((lightDir2 - rd) / 2.0, normal), 0., 1.), 32.0));
    
    if (RayMarching1(p + normal * SURFACE_DIST * 1.75, lightDir2) < length(lightPos2 - p)) {
        diffuse2 *= 0.5;
        specular2 *= 0.0;
    }
    return ambient + diffuse1 + specular1 + diffuse2 + specular2;
}
//---------------//

//----Model 2----//
float Object2(vec3 p) {
    vec4 sphere = vec4(0, 1, 5, 0.3);
    sphere.xz += 2.0 * vec2(sin(time), cos(time));
    return sphereSDF(p, sphere);
}
float RayMarching2(vec3 ro, vec3 rd) {
    float dO = 0.;
    for (int i = 0; i < MAX_STEPS; i ++) {
        vec3 P = ro + dO * rd;
        float ds = Object2(P);
        dO += ds;
        if (ds < SURFACE_DIST || dO > MAX_DIST) break;
    }
    return dO;
}
vec3 ObjectNormal2(vec3 p) {
    float d = Object2(p);
    vec2 e = vec2(0.01, 0.0);
    
    vec3 n = d - vec3(
        Object2(p - e.xyy),
        Object2(p - e.yxy),
        Object2(p - e.yyx)
    );
    return normalize(n);
}
vec3 ObjectLight2(vec3 p, vec3 rd) {
    vec3 normal = ObjectNormal2(p);
    float r = abs(dot(normal, rd));
    return vec3(0, 0, r);
}
//---------------//

//----Model 3----//
float Object3(vec3 p) {
    vec4 sphere = vec4(0, 1, 5, 0.3);
    sphere.xz += 2.0 * vec2(sin(time + 3.14), cos(time + 3.14));
    return sphereSDF(p, sphere);
}
float RayMarching3(vec3 ro, vec3 rd) {
    float dO = 0.;
    for (int i = 0; i < MAX_STEPS; i ++) {
        vec3 P = ro + dO * rd;
        float ds = Object3(P);
        dO += ds;
        if (ds < SURFACE_DIST || dO > MAX_DIST) break;
    }
    return dO;
}
vec3 ObjectNormal3(vec3 p) {
    float d = Object3(p);
    vec2 e = vec2(0.01, 0.0);
    
    vec3 n = d - vec3(
        Object3(p - e.xyy),
        Object3(p - e.yxy),
        Object3(p - e.yyx)
    );
    return normalize(n);
}
vec3 ObjectLight3(vec3 p, vec3 rd) {
    vec3 normal = ObjectNormal3(p);
    float r = abs(dot(normal, rd));
    return vec3(r, 0, 0);
}
//---------------//

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    vec3 ro = vec3(0, 2, 0);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));
    
    vec3 col = vec3(0);
    
    //----Object1----//
    float d1 = RayMarching1(ro, rd);
    vec3 col1 = ObjectLight1(ro + rd * d1, rd);
    //---------------//
    
    //----Object2----//
    float d2 = RayMarching2(ro, rd);
    vec3 col2 = ObjectLight2(ro + rd * d2, rd);
    if (d2 > MAX_DIST) col2 = vec3(0);
    //---------------//
     
    //----Object3----//
    float d3 = RayMarching3(ro, rd);
    vec3 col3 = ObjectLight3(ro + rd * d3, rd);
    if (d3 > MAX_DIST) col3 = vec3(0);
    //---------------//
     
    col = col1;
    
    if (d2 < d1) col += col2;
    if (d3 < d1) col += col3;
    // Output to screen
    glFragColor = vec4(col,1.0);
}
