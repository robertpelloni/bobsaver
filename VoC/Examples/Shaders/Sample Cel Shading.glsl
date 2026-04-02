#version 420

// original https://www.shadertoy.com/view/wslyzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.01

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0.0, 1.0);
    
    vec3 c = a + t*ab;
    
    return length(p-c)-r;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    //t = clamp(t, 0.0, 1.0);
    
    vec3 c = a + t*ab;
    
    float x = length(p-c)-r;
    float y = (abs(t-0.5)-0.5)*length(ab);
    float e = length(max(vec2(x, y), 0.0));
    float i = min(max(x, y), 0.0);
    return e+i;
}

float sdTorus(vec3 p, vec2 r) {
    float x = length(p.xz)-r.x;
    return length(vec2(x, p.y))-r.y;
}

float dBox(vec3 p, vec3 s) {
    return length(max(abs(p)-s, 0.0));
}

float GetDist(vec3 p) {
    float pd = p.y;
    
    vec3 bp1 = p-vec3(5, 1.5, 0.0);
    vec3 bp2 = p-vec3(4, 1.5, 0.0);
    vec3 bp3 = p-vec3(0, 1.5, 0.0);
    vec3 bp4 = p-vec3(-4.5, 1.5, 0.0);
    bp1.yz *= Rot(time*3.141*0.5);
    bp2.yz *= Rot((time*3.141*0.5)+(3.141*0.5));
    bp3.xz *= Rot((-time*3.141*0.125));
    
    float bd1 = sdTorus(bp1, vec2(1, 0.5));
    float bd2 = sdTorus(bp2, vec2(1, 0.5));
    float bd3 = dBox(bp3, vec3(1.0, 0.5, 1.0));
    float bd4 = sdCapsule(bp4, vec3(1.5, sin(time*3.141*0.25), 2.0), vec3(0.5, cos(time*3.141*0.25), -2.0), 0.5);
    float d = min(bd1, bd2);
    d = min(d, bd3);
    d = min(d, bd4);
    d = min(d, pd);
    
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(0.01, 0.0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx)
    );
    
    return normalize(n);
}

vec4 GetLight(vec3 p) { //This is probably the most important part about Cel shading
    vec3 lightPos[3];
    lightPos[0] = vec3(5, 6, 0);
    lightPos[1] = vec3(-2, 7, 1);
    lightPos[2] = vec3(-4, 10, 10);
    
    vec3 lightCol[3];
    lightCol[0] = vec3(0.3, 0.2, 0.05);
    lightCol[1] = vec3(0.4, 0.2, 0.2);
    lightCol[2] = vec3(0.1, 0.1, 0.2);
    
    vec4 col = vec4(0.0);
    
    for(int i; i<3; i++) {
        vec3 l = normalize(lightPos[i]-p);
        vec3 n = GetNormal(p);
        
        float dif = clamp(dot(n, l), 0.0, 1.0);
        float d = RayMarch(p+n*SURF_DIST*2.0, l);
        if(d<length(lightPos[i]-p)) dif *= 0.1;
        
        col += floor(dif+0.5)*vec4(lightCol[i], 1.0); //This rounds the lighting value, so it really looks flat.
    }
    
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-(0.5*resolution.xy))/resolution.y;
    vec4 col = vec4(0);
    
    vec3 ro = vec3(0.0, 6.0, -10.0);
    vec3 rd = normalize(vec3(vec2(uv.x, uv.y-0.46)*Rot(3.141*sin(time*3.141*0.2)*0.01), 1.0));
    
    ro.zx *= Rot((time*3.141*0.125)+3.141); //Origin rotation
    
    rd.zy *= Rot(sin(-time*3.141*0.5)*3.141*0.01); //Direction rotation, this line makes the camera go up and down
    rd.zx *= Rot((time*3.141*0.125)+3.141); //This one makes the camera rotate along the center
    
    float d = RayMarch(ro, rd);
    
    vec3 p = ro + rd * d;
    
    vec4 dif = GetLight(p);
    dif *= (1.0/d)*8.0; //Multiply some smoothness to the lighting, semi shading, just a distance modifier
    col = dif;
    col += (d*0.007*vec4(0.1, 0.56, 0.8, 0.0)); //Add a little lovely fog effect in the background
    
    glFragColor = col;
}
