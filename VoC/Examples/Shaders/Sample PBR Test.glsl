#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//PBR(Physically Based Rendering) test
//render sphere[box,mix]
//#define SPHERE //BOX MIX

#define PI         3.1415926535897932384626
#define ZERO         vec3(0.0)
#define X        vec3(1.0,0.0,0.0)
#define Y        vec3(0.0,1.0,0.0)
#define Z        vec3(0.0,0.0,1.0)
#define R        1.0
#define T        5

#define EPSILON    0.001
#define MAX_DIST    80.0
#define MAX_ITER    100

#define LIGHT_NUM    1
#define BALL_ROW    4.0
#define BALL_COL    4.0
#define RADIUS        1.5

#define ALBEDO      vec3(0.9)
#define METALLIC     1.0
#define ROUGHNESS     1.0
#define F0        mix(vec3(0.04),ALBEDO,metallic)
#define AO        1.0

float rand(vec3 seed){
    return fract(sin(dot(seed, vec3(12.9898,78.233,233.33))) * 43758.5453);
}

float rand(vec2 seed){
    return rand(vec3(seed,0.0));
}

float rand(float seed){
    return rand(vec3(seed,0.0,0.0));
}

float noise2(vec2 uv){
    vec2 base = floor(uv*R);
    vec2 pot = fract(uv*R);
    vec2 f = smoothstep(0.0, 1.0, pot);  
    return mix(
        mix(rand(base),rand(base+X.xy),f.x),
        mix(rand(base+X.yx),rand(base+X.xx),f.x),
        f.y
    );
} 

float noise3(vec3 pos){
    vec3 base = floor(pos*R);
    vec3 pot = fract(pos*R);
    vec3 f = smoothstep(0.0,1.0,pot);
    float w1 = mix(rand(base),    rand(base+X),    f.x);
    float w2 = mix(rand(base+Z),  rand(base+X+Z),  f.x);
    float w3 = mix(rand(base+Y),  rand(base+X+Y),  f.x);
    float w4 = mix(rand(base+Y+Z),rand(base+X+Y+Z),f.x);
    return mix(
        mix(w1,w3,f.y),
        mix(w2,w4,f.y),
        f.z
    );
}

float fbm2(vec2 uv) {
    float total = 0.0, amp = 1.0;
    for (int i = 0; i < T; i++){
        total += noise2(uv) * amp; 
        uv *= 2.0;
        amp *= 0.5;
    }
    return 1.0-exp(-total*total);
} 

float fbm3(vec3 pos){
    float total = 0.0, amp = 1.0;
    for (int i = 0; i < T; i++){
        total += noise3(pos) * amp; 
        pos *= 2.0;
        amp *= 0.5;
    }
    return 1.0-exp(-total*total);
}
//
vec3 fresnelSchlick(float cosTheta,float metallic){
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float DistributionGGX(vec3 N, vec3 H, float roughness){
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    return nom / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness){
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;
    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    return nom / denom;
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness){
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}
//
float box(vec3 pos,vec3 center,vec3 size){
      vec3 d = abs(pos-center) - size;
     return length(max(d,0.0));
}

float sphere(vec3 pos, vec3 center, float radius){
    return distance(pos,center)-radius;
}
// return (distance, id)
vec2 dist(vec3 pos){
    float id = 0.0;
    float d = MAX_DIST;
    float obj = id;
    for(float i = -BALL_ROW+1.0; i <= BALL_ROW-1.0; i+=2.0){
        for(float j = -BALL_COL+1.0; j <= BALL_COL-1.0; j+=2.0){
            #if defined(SPHERE)
            float _d = sphere(pos,1.15*(j*X+i*Y)*RADIUS,RADIUS);
            #elif defined(BOX)
            float _d = box(pos,1.15*(j*X+i*Y)*RADIUS,vec3(RADIUS));
            #else 
            float s = step(0.5,rand(vec3(j,i,floor(0.1*time))));
            float _d = mix(
                sphere(pos,1.15*(j*X+i*Y)*RADIUS,RADIUS),
                box(pos,1.15*(j*X+i*Y)*RADIUS,vec3(RADIUS))
                ,s);
            #endif
            d = min(d,_d);
            if(d == _d){
                obj = id;
            }
            id++;
        }
    }
    //d = min(d,box(pos,2.0*X.xxx));
    return vec2(d,obj);
}

vec3 setCamera(vec2 uv,vec3 pos,vec3 lookat,vec3 up){
    vec3 camDir = normalize(lookat-pos);
    vec3 camUp = normalize(up);
    vec3 camRight = cross(camDir,camUp);
    return normalize(uv.x*camRight+uv.y*camUp+5.0*camDir);
}

vec2 rayMarching(vec3 ro,vec3 rd){
    vec2 d = vec2(EPSILON);
    float h = d.x;
    for(int i = 0; i<MAX_ITER; i++){
        d = dist(ro+rd*h);
        if(d.x < EPSILON){ 
            break;
        }
        if(h > MAX_DIST){
            return vec2(MAX_DIST);
        }
        h += d.x;
    }
    return vec2(h,d.y);
}

vec3 calcNormal(vec3 pos){
     return normalize(vec3(
            dist(pos+X*EPSILON).x - dist(pos - X*EPSILON).x,
            dist(pos+Y*EPSILON).x - dist(pos - Y*EPSILON).x,
            dist(pos+Z*EPSILON).x - dist(pos - Z*EPSILON).x
        ));
}

void main( void ) {
    vec2 uv = ( 2.0 * gl_FragCoord.xy - resolution.xy ) / resolution.y;
    vec2 touch = (2.0*mouse-1.0)*resolution.xy/resolution.y;
        
    vec3 ro = vec3(-30.0*touch,35.0);
    vec3 rd = setCamera(uv,ro,ZERO,Y);
    vec2 h = rayMarching(ro,rd);
    vec3 color = ZERO;
    if(h.x < MAX_DIST){
        vec3 Lo = ZERO;
        float t = 0.0 * time;
        vec3 light = 10.0*vec3(sin(t),0.0,cos(t));
        vec3 pos = ro+rd*h.x;
        vec3 N = calcNormal(pos);
        vec3 L = normalize(light-pos);
        vec3 V = normalize(ro-pos);
        vec3 H = normalize(V+L);
        float row = floor(h.y / BALL_COL);
        float col = h.y - row * BALL_COL;
        float k = smoothstep(0.2,0.8,fbm3(pos));
        vec3 albedo = ALBEDO-0.56*vec3(0.0,k,k);
        float roughness = ROUGHNESS*(k)*(row+1.0)/BALL_ROW;
        float metallic = METALLIC*(1.0-k)*(col+1.0)/BALL_COL;
        vec3 F  = fresnelSchlick(max(dot(H, V), 0.0),metallic);
        float NDF = DistributionGGX(N, H, roughness);       
        float G   = GeometrySmith(N, V, L, roughness);
        
        float dis = 1.0;//length(light-pos);
            float attenuation = 1.0 / (dis * dis);
            vec3 radiance     = vec3(1.0,1.0,1.0) * attenuation;

        vec3 nominator  = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001; 
        vec3 specular     = nominator / denominator;
        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        kD *= 1.0 - metallic; 
        float NdotL = max(dot(N, L), 0.0);        
           Lo += (kD * albedo / PI + specular) * radiance * NdotL;
        vec3 ambient = vec3(0.03) * ALBEDO * AO;
        color = ambient + Lo;  
        color = color / (color + vec3(1.0));
        color = pow(color, vec3(1.0/2.2)); 
        
        //color = vec3(fbm3(pos));
        
        //vec3 diffuse = vec3(1.0)*max(0.12,dot(N,L));
        //color = diffuse;
    }
    
    glFragColor = vec4(color, 1.0);
}
