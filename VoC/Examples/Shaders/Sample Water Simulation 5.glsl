#version 420

// original https://www.shadertoy.com/view/MscGRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 lightDir = normalize(vec3(0, -0.3, -1));
const vec3 lightPos = vec3(0, 2, 4);
const float lightPow = 0.5;

const float ambientLightPow = 0.3;
const vec3 planePos = vec3(0, -1, 0);
const vec3 planeNormal = vec3(0, 1, 0);

const vec3 waterPos = vec3(0, 0, 0);
const vec3 waterNormal = vec3(0, 1, 0);
const float waterDirtiness = 0.4;

const vec3 white = vec3(1, 1, 1);
const vec3 black = vec3(0, 0, 0);
const vec3 skyColor = vec3(0.7, 1.0, 1.0);
const vec3 waterColor = vec3(176.0/255.0, 224.0/255.0, 230.0/255.0);

const int NUM_STEPS = 5;
const float EPSILON = 0.0001;

vec3 refractLightDir = refract(lightDir, waterNormal, 1.0/1.5);

float hash( vec2 p ) {
    float h = dot(p,vec2(127.1,311.7));    
    return fract(sin(h)*43758.5453123);
}
float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );    
    vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

float specular(vec3 n,vec3 l,vec3 e,float s) {    
    return pow(max(dot(reflect(e,n),-l),0.0),s);
}

float map(vec3 p)
{
    return p.y - 0.3*noise(p.xz+vec2(time));
}

float getHeight(vec3 ori, vec3 dir, out vec3 p)
{
    float tm = 0.0;
    float tx = 1000.0;    
    float hx = map(ori + dir * tx);
    if(hx > 0.0) {
        p = vec3(0, 0, 0);
        return 0.0;   
    }
    float hm = map(ori + dir * tm);    
    float tmid = 0.0;
    for(int i = 0; i < NUM_STEPS; i++) {
        tmid = mix(tm,tx, hm/(hm-hx));                   
        p = ori + dir * tmid;                   
        float hmid = map(p);
        if(hmid < 0.0) {
            tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
    }
    return tmid;
}

vec3 getNormal(vec3 p, float eps)
{
    vec3 normal;
    normal.y = map(p);
    normal.x = map(vec3(p.x+eps, p.y, p.z)) - normal.y;
    normal.z = map(vec3(p.x, p.y, p.z+eps)) - normal.y;
    normal.y = eps;
    return normalize(normal);
}

bool intersectPlane(out vec3 color, vec3 ori, vec3 dir)
{
    float a = dot(dir, planeNormal);
    if (a > 0.0) {
        color = white;
        return false;
    } else {
        float dToPlane = dot(ori-planePos, planeNormal);
        vec3 intersectPt = ori+dir*abs(dToPlane/a);
        if (fract((floor(intersectPt.x)+floor(intersectPt.z))/2.0) == 0.5)
        {
            color = black;
            color += vec3(specular(planeNormal, refractLightDir, dir, 60.0));
            color += ambientLightPow*white;
            color = mix(color, waterColor, waterDirtiness);
        } else {
            color = black;    
        }
        return true;
    }
}

bool intersectWater(out vec3 color, vec3 ori, vec3 dir)
{
    float a = dot(dir, waterNormal);
    if (a > 0.0) {
        color = white;
        return false;
    } else {
        
                                   
                                   
        vec3 intersectPt, intersectNormal;
        getHeight(ori, dir, intersectPt);
        vec3 dist = intersectPt-ori;
        intersectNormal = getNormal(intersectPt, dot(dist, dist)*EPSILON);
        
        vec3 refractColor, reflectColor;
        
        //plane
        vec3 refractDir = refract(dir, intersectNormal, 1.0/1.5);
        intersectPlane(refractColor, intersectPt, refractDir);
        
        // reflect
        reflectColor = 80.0* vec3(specular(intersectNormal, lightDir, dir, 100.0));
        
        // fresnel
        float r0 = pow((1.0-1.5)/(1.0+1.5), 2.0);
        float fresnel = r0+(1.0-r0)*(pow(1.0-abs(dot(dir, intersectNormal)), 5.0));
                                      
        color = refractColor*(1.0-fresnel) + reflectColor*fresnel;
        return true; 
    }
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv*2.0 - 1.0;
    vec3 ori = vec3(0, 2, 0);
    vec3 dir = normalize(vec3(uv, 1.0));
                         
    vec3 color;
    intersectWater(color, ori, dir)  ;             
    glFragColor = vec4(mix(skyColor, color, 
                    smoothstep(0.0, -0.1, dir.y)), 1.0);
}
