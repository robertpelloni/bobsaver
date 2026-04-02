#version 420

// original https://www.shadertoy.com/view/tlSBz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A good occasion for me to learn texture filtering from Inigo Quilez:
// https://iquilezles.org/articles/filtering/
//
// I hope I implemented it correctly!

const float azimuthSpeed = 0.3;
const float altitudeSpeed = 0.4;

const float fov = 35.0;

// Quality of filtering
// Try 1.0 to see the difference.
const float aa = 4.0;

const float roomSize = 2.0;
const vec3 lightColor = 5.0*vec3(1.0,0.8,0.5);

const vec3 ambient = vec3(0.05,0.00,0.0);
const vec2 lamp = vec2(0.8,1.6);

const vec2 delta = vec2(0.0,0.01);

float hash( float x ) {
    return fract(sin(x * 12.9898) * 43758.5453);
}
float noise(float x) {
    float p = floor(x);
    float f = x-p;
    return mix(hash(p),hash(p+1.0),f);
}

float sdFloor(vec3 p) {
    return p.y;
}
float sdLamp(vec3 p) {
    float radius = length(p.xz-lamp);
    
    float cyl = max(p.y-0.5, radius-0.007);
    float cone = max(p.y-0.8,max(0.5-p.y,0.5*(radius-0.007-pow(p.y-0.5,2.0))));
    return min(cyl,cone);
}
float sdLamps(vec3 p) {
    vec3 q = p;
    q.xz = abs(q.xz);
    return sdLamp(q);
}
float sdCurtain(vec3 p) {
    // Sending p to the region p.x >= abs(p.z)
    float sum = abs(p.x+p.z);
    float dif = abs(p.x-p.z);
    p.xz = 0.5*vec2(sum+dif,sum-dif);

    return max(0.05-p.y,
        0.5*(abs(p.x - roomSize + 
        0.025*smoothstep(-2.0,0.0,-p.y) * sin((60.0+6.0*noise(15.0*p.z))*p.z))-0.05));
}
float sd(vec3 p) {
    float df = sdFloor(p);
    float dc = sdCurtain(p);
    float dl = sdLamps(p);
    return min(min(df,dc),dl);
}
int getId(vec3 p) {
    float df = sdFloor(p);
    float dc = sdCurtain(p);
    float dl = sdLamps(p);
    return df < min(dc,dl) ? 0 : dc < dl ? 1 : 2;
}
vec3 normalCurtain(vec3 p) {
    float d = sdCurtain(p);
    return normalize(vec3(
        sdCurtain(p+delta.yxx),
        sdCurtain(p+delta.xyx),
        sdCurtain(p+delta.xxy))-d);
}
vec3 normalLamps(vec3 p) {
    float d = sdLamps(p);
    return normalize(vec3(
        sdLamps(p+delta.yxx),
        sdLamps(p+delta.xyx),
        sdLamps(p+delta.xxy))-d);
}
vec3 floorColor(vec2 p) {
    p.xy *= 3.0;
    p.x = abs(mod(p.x,1.0)-0.5);
    vec3 col;
    float a = mod(p.y-p.x, 0.5);
    if(a<0.25)
        col = vec3(0.1,0.0,0.0);
    else
        col = vec3(1.0);

    return col;
}
// Filtering the floor procedural texture
// https://iquilezles.org/articles/filtering/
vec3 floorColor(vec2 p, vec2 px, vec2 py, vec2 pxy) {
    vec3 col = vec3(0.0);
    vec2 pbot, ptop;
    float e = 1.0/aa;
    for(float i = 0.5*e; i < 1.0; i += e) {
        pbot = mix(p, px, i);
        ptop = mix(py, pxy, i);
        for(float j = 0.5*e; j < 1.0; j += e) {
            col += floorColor(mix(pbot, ptop, j));
        }
    }
    col /= (aa*aa);
    return col;
}

float march(vec3 start, vec3 dir) {
    float t = 0.0, d = 1.0;
    float epsilon = 0.5/resolution.y;
    for(int i=0; i<200; i++) {
        if(d<epsilon || t>100.0) break;
        d = sd(start + t * dir);
        t += d;
    }
    return t;
}

// Taken from Inigo Quilez:
// https://iquilezles.org/articles/rmshadows/
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = sd(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

vec3 shade(vec3 pos, vec3 toEye, vec3 normal, vec3 color, vec3 lightPosition, float reflectivity) {
    vec3 lightDir = lightPosition - pos;
    float lightDist = length(lightDir);
    lightDir = lightDir/lightDist;
  
    // Diffuse
    float diff = max(dot(normal, lightDir), 0.0);

    // Specular
    vec3 h = normalize(lightDir + toEye);
    float spec = pow(max(dot(h, normal), 0.0), 20.0) * reflectivity;
    
    float sh = softshadow(pos, lightDir, 0.1, lightDist, 15.0);
    
    return sh * (diff * color + spec) * lightColor/(1.0+10.0*lightDist*lightDist);
}
vec3 shade(vec3 pos, vec3 toEye, vec3 normal, vec3 color, float reflectivity) {
    vec3 col = vec3(0.0);
    for(float i=-1.0; i<1.1; i+=2.0) {
        for(float j=-1.0; j<1.1; j+=2.0) {
            col += shade(pos,toEye,normal,color,vec3(i*lamp.x,0.9,j*lamp.y),reflectivity);
        }
    }
    return ambient * color + col;
}

vec3 rayColor(vec3 start, vec3 dir, vec3 dirx, vec3 diry, vec3 dirxy) {
    float minD;
     float t = march(start, dir);

    vec3 p = start + t * dir;
    int id = getId(p);
    
    vec3 normal;
    vec3 albedo;
       float refl;
    
    switch(id) {
        case 0:// Floor
            albedo = floorColor(p.xz,
                start.xz-dirx.xz * start.y/dirx.y,
                start.xz-diry.xz * start.y/diry.y,
                start.xz-dirxy.xz * start.y/dirxy.y);
            refl = 0.04;
            normal = vec3(0.0,1.0,0.0);
            break;
        case 1:// Curtain
            albedo = vec3(0.3,0.0,0.0);
            refl = 0.0;
            normal = normalCurtain(p);            
            break;
        default:// Lamp
            albedo = vec3(0.3);
            refl = 1.0;
            normal = normalLamps(p);
    }
    
    return shade(p, -dir, normal, albedo, refl);
}
mat3 viewMatrix(vec3 cam, vec3 cen, vec3 up) {
     vec3 w = normalize(cam-cen);
    vec3 u = normalize(cross(up, w));
    vec3 v = cross(w, u);
    
    return mat3(u,v,w);
}
void main(void)
{
    float azimuth = azimuthSpeed*time;
    float altitude = 0.35+0.1*sin(altitudeSpeed*time);
    float camDistance = 1.8;
    
    vec3 cam = camDistance * vec3(sin(azimuth)*cos(altitude),sin(altitude),cos(azimuth)*cos(altitude));
    vec3 center = vec3(0.0,0.35,0.0), up = vec3(0.0, 1.0, 0.0);
    
    mat3 m = viewMatrix(cam, center, up);

    vec2 uv = 2.0*(gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    vec2 uvx = 2.0*(gl_FragCoord.xy + vec2(1,0) - 0.5 * resolution.xy)/resolution.y;
    vec2 uvy = 2.0*(gl_FragCoord.xy + vec2(0,1) - 0.5 * resolution.xy)/resolution.y;
    vec2 uvxy = 2.0*(gl_FragCoord.xy + vec2(1,1) - 0.5 * resolution.xy)/resolution.y;

    float k = tan(0.5*fov*0.01745);
    vec3 dir = normalize(m * vec3(k*uv,-1.0));
    vec3 dirx = normalize(m * vec3(k*uvx,-1.0));
    vec3 diry = normalize(m * vec3(k*uvy,-1.0));
    vec3 dirxy = normalize(m * vec3(k*uvxy,-1.0));

    vec3 color = rayColor(cam, dir, dirx, diry, dirxy);
    
    // Vignette
    // Taken from https://www.shadertoy.com/view/XsGyDh
    uv = gl_FragCoord.xy/resolution.xy,
    color = mix(color, vec3(0), (1. - pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), 0.25)));

    // Gamma correction
    color = pow(color,vec3(0.45));
    
    glFragColor = vec4(color,1.0);
}
