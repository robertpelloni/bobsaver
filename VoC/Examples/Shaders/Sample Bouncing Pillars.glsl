#version 420

// original https://www.shadertoy.com/view/WldSDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST 0.01

#define CAMERA_DIST 3.0
#define CAMERA_HEIGHT 2.0
#define BOXES 2.0
#define BOX_WIDTH 0.2

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

struct ray {
    vec3 pos;
    vec3 dir;
};

ray create_camera_ray(vec2 uv, vec3 camPos, vec3 lookAt, float zoom){
    vec3 f = normalize(lookAt - camPos);
    vec3 r = cross(vec3(0.0,1.0,0.0),f);
    vec3 u = cross(f,r);
    vec3 c=camPos+f*zoom;
    vec3 i=c+uv.x*r+uv.y*u;
    vec3 dir=i-camPos;
    return ray(camPos,normalize(dir));
}

float GetDist(vec3 p) {
    vec4 sphere = vec4(0, 1, 6, 1);
    
    float boxDist = MAX_DIST;
    for(float x = -BOXES/2.0; x<BOXES/2.0; x += BOX_WIDTH) {
        for(float z = -BOXES/2.0; z<BOXES/2.0; z += BOX_WIDTH) {
            
            float sin_offset = pow(distance(vec2(x, z), vec2(0.0)), 3.0);
            float curBoxDist = sdBox(p - vec3(x, 0.3*(sin(time*3.0 + sin_offset)+1.0), z), vec3(BOX_WIDTH, 0.4, BOX_WIDTH));
            boxDist = min(curBoxDist, boxDist);
            
        }
    }
    float planeDist = p.y;
    
    float d = min(boxDist, planeDist);
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(0.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0, 5, 6);
    
    lightPos.xz += vec2(sin(time), cos(time))*2.;
    
    vec3 l = normalize(lightPos - p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    
    float d = RayMarch(p+n*SURF_DIST*2., l);
    if(d < length(lightPos-p)) dif *= .1;
    
    return dif;
}
    
void main(void)
{
    
    // where 0.0 is the center
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0);
    
    ray r = create_camera_ray(uv, vec3(cos(time)*CAMERA_DIST, CAMERA_HEIGHT, sin(time)*CAMERA_DIST), vec3(0.0), 1.0);
    
    vec3 ro = r.pos;
    vec3 rd = r.dir;
    
    float d = RayMarch(ro, rd);
    
    vec3 p = ro + rd * d;
    
    float diffuse = GetLight(p);
   
    col = vec3(diffuse);
    
    //col = GetNormal(p);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
