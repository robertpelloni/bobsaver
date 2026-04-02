#version 420

// original https://www.shadertoy.com/view/MldGDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    The BRDF used in this shader is based on those used by Disney and Epic Games.
    
    The input parameters and individual components are modelled after the ones
    described in

        https://de45xmedrsdbp.cloudfront.net/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf

    The various components are then combined based on Disney's PBR shader, found here

        https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf
    
    I'd recommend reading this for a description of what the parameters in this BRDF do

        http://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf

    
*/

//#define COLUMN_COL vec3(1.0, 0.858824, 0.568627)
#define COLUMN_COL vec3(1.0, 0.0, 0.0)

//#define FLOOR_COL_A vec3(0.8)
//#define FLOOR_COL_B vec3(0.2)
#define FLOOR_COL_A vec3(0.0, 0.0, 1.0)
#define FLOOR_COL_B vec3(1.0, 1.0, 1.0)

float closeObj = 0.0;
const float PI = 3.14159;

mat3 rotX(float d){
    float s = sin(d);
    float c = cos(d);
    return mat3(1.0, 0.0, 0.0,
                0.0,   c,  -s,
                0.0,   s,   c );
}

mat3 rotY(float d){
    float s = sin(d);
    float c = cos(d);
    return mat3(  c, 0.0,  -s,
                0.0, 1.0, 0.0,
                  s, 0.0,   c );
}

float capsule(vec3 p, vec3 a, vec3 b, float r){
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float torus(vec3 p, vec2 t)
{
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

vec2 vecMin(vec2 a, vec2 b){
    if(a.x <= b.x){
        return a;
    }
    return b;
}

vec2 mapMat(vec3 p){
    vec3 q = p;
    p = vec3(mod(p.x, 5.0) - 2.5, p.y, mod(p.z, 5.0) - 2.5);
    float qpi = 3.141592 / 4.0;
    float sub = 10000.0;
    for(float i = 0.0; i < 8.0; i++){
        float x = 0.2 * cos(i * qpi);
        float z = 0.2 * sin(i * qpi);
        vec3 transp = p - vec3(x, 0.0, z);
        vec3 a = vec3(x, 1.2, z);
        vec3 b = vec3(x, -1.2, z);
        sub = min(sub, capsule(transp, a, b, 0.1));
    }
    float ttorus = torus(p - vec3(0.0, -1.5, 0.0), vec2(0.22));
    float btorus = torus(p - vec3(0.0, 1.5, 0.0), vec2(0.22));
    float u = min(btorus, ttorus);
    vec2 column = vec2(min(u, max(-sub, length(p.xz) - 0.35)), 2.0);
    vec2 ctorus = vec2(torus(rotX(time) * rotY(time) * (q - vec3(0.0, 0.0, 5.0)), vec2(1.0, 0.5)), 2.0);
    vec2 flo = vec2(q.y + 1.5, 1.0);
    vec2 roof = vec2(-q.y + 1.5, 1.0);
    return vecMin(ctorus, vecMin(column, vecMin(flo, roof)));
}

//Returns the min distance
float map(vec3 p){
    return mapMat(p).x;
}

float trace(vec3 ro, vec3 rd){
    float t = 1.0;
    float d = 0.0;
    float w = 1.4;
    float ld = 0.0;
    float ls = 0.0;
    float s = 0.0;
    float cerr = 10000.0;
    float ct = 0.0;
    float pixradius = 0.4 / resolution.x;
    vec2 c;
    int inter = 0;
    for(int i = 0; i < 256; i++){
        ld = d;
        c = mapMat(ro + rd * t);
        d = c.x;
        
        //Detect intersections missed by over-relaxation
        if(w > 1.0 && abs(ld) + abs(d) < s){
            s -= w * s;
            w = 1.0;
            t += s;
            continue;
        }
        s = w * d;
        
        float err = d / t;
        
        if(abs(err) < abs(cerr)){
            ct = t;
            cerr = err;
        }
        
        //Intersect when d / t < one pixel
        if(abs(err) < pixradius){
            inter = 1;
            break;
        }
        
        t += s;
        if(t > 50.0){
            break;
        }
    }
    closeObj = c.y;
    if(inter == 0){
        ct = -1.0;
    }
    return ct;
}

//Approximate normal
vec3 normal(vec3 p){
    return normalize(vec3(map(vec3(p.x + 0.0001, p.yz)) - map(vec3(p.x - 0.0001, p.yz)),
                          map(vec3(p.x, p.y + 0.0001, p.z)) - map(vec3(p.x, p.y - 0.0001, p.z)),
                          map(vec3(p.xy, p.z + 0.0001)) - map(vec3(p.xy, p.z - 0.0001))));
}

vec3 camPos = vec3(0.0);
vec3 lightPos = vec3(0.0);

//Determine if a point is in shadow - 1.0 = not in shadow
float shadow(vec3 ro, vec3 rd){
    float t = 0.01;
    float d = 0.0;
    float shadow = 1.0;
    for(int iter = 0; iter < 256; iter++){
        d = map(ro + rd * t);
        if(d < 0.0001){
            return 0.0;
        }
        if(t > length(ro - lightPos) - 0.5){
            break;
        }
        shadow = min(shadow, 128.0 * d / t);
        t += d;
    }
    return shadow;
}

float occlusion(vec3 ro, vec3 rd){
    float k = 1.0;
    float d = 0.0;
    float occ = 0.0;
    for(int i = 0; i < 25; i++){
        d = map(ro + 0.1 * k * rd);
        occ += 1.0 / pow(2.0, k) * (k * 0.1 - d);
        k += 1.0;
    }
    return 1.0 - clamp(2.0 * occ, 0.0, 1.0);
}

//Square
float sqr(float x){
  return x * x;
}

//Diffusion normalisation
float diff(float albedo){
  return albedo / PI;
}

//GGX NDF
float specD(float NdotH, float a){
  float asqr = sqr(a);
  float NdotHsqr = sqr(NdotH);
  return asqr / (PI * sqr((NdotHsqr) * (asqr - 1.0) + 1.0));
}

float G1(float NdotX, float k){
  return NdotX / (NdotX * (1.0 - k) + k);
}

//Geometric attenuation term
float specG(float NdotV, float NdotL, float k){
  k /= 2.0;
  return G1(NdotV, k) * G1(NdotL, k);
}

//Schlick fresnel approximation used by Unreal Engine
float fresnel(float AdotB){
  float power = pow(2.0, (-5.55473 * AdotB - 6.98316) * AdotB);
  return 0.04 + (1.0 - 0.04) * power;
}

vec3 BRDF(vec3 L, vec3 V, vec3 N, vec3 c, float metallic, float roughness, float s, float o){
  vec3 H = normalize(L + V);
  float NdotH = dot(N, H);
  float NdotL = dot(N, L);
  float NdotV = dot(N, V);
  float VdotH = dot(V, H);
  float alpha = roughness * roughness;

  float conductor = 1.0 - metallic;

  vec3 specCol = mix(vec3(1.0), c, metallic);
  
  float FresL = fresnel(NdotL);
  float FresV = fresnel(NdotV);
  float Fresd90 = 0.5 + 2.0 * sqr(VdotH) * roughness;
  float Fresd = mix(1.0, Fresd90, FresL) * mix(1.0, Fresd90, FresV); 
  
  float Ds = specD(NdotH, alpha);
  float FresH = fresnel(VdotH);
  vec3 Fress = mix(specCol, vec3(1.0), FresH);
  float Gs = specG(NdotV, NdotL, roughness);

  return (diff(conductor) * Fresd * max(0.0, NdotL) * o * c + Gs * Fress * Ds * floor(s)) - (0.25 - 0.25 * s) * c;
}

vec3 colour(vec3 p, float id){
    vec3 n = normal(p);
    vec3 l = normalize(lightPos - p);
    vec3 v = normalize(camPos - p);
    
    vec3 amb = 0.25 * vec3(1.0);
    
    float s = shadow(p, l);
    
    float o = occlusion(p, n);
    
    if(id == 1.0){
        vec3 col;
        vec2 t = mod(floor(p.xz), 2.0);
        if(t == vec2(0.0) || t == vec2(1.0)){
            col = FLOOR_COL_A;
        }else{
            col = FLOOR_COL_B;
        }
        return BRDF(l, v, n, col, 0.4, 0.2, s, o);
    }
    if(id == 2.0){
        float metal = mouse.x*resolution.x / resolution.x;
        float rough = mouse.y*resolution.y / resolution.y;
        if(rough == 0.0 && metal == 0.0){
            metal = 0.1;
            rough = 0.1;
        }
        return BRDF(l, v, n, COLUMN_COL, metal, rough, s, o);
    }
    return vec3(0.0, 1.0, 0.0);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    camPos = vec3(0.0 , 0.0, 0.0);
    lightPos = vec3(sin(time) * 3.0, 0.0, 0.0);
    vec3 ro = camPos;
    vec3 rd = normalize(vec3(uv, 1.0));
    float d = trace(ro, rd);
    vec3 c = ro + rd * d;
    vec3 col = vec3(0.0);
    //If intersected
    if(d > 0.0){
        //Colour the point
        col = colour(c, closeObj);
        //Apply fog
        col *= 1.0 / exp(d * 0.1);
    }else{
        col = vec3(0.0);
    }
    col = pow( col, vec3(0.4545) );
    glFragColor = vec4(col,1.0);
}
