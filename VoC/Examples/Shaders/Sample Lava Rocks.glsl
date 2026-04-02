#version 420

// original https://www.shadertoy.com/view/wdByDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.01

mat2 rot(float r) {
    float s = sin(r);
    float c = cos(r);
    return mat2(c, -s, s, c);
}

vec2 h22(vec2 p)
{
    vec3 a = fract(p.xyx * vec3(123.34, 234.34, 345.65));
    a += dot(a, a + 34.45);
    return fract(vec2(a.x * a.y, a.y * a.z));
}

float voronoi(vec2 uv, float t) {
    float minDist = 100.0;
    float cellIndex = 0.0;
    
    uv *= 3.0;

    vec2 gv = fract(uv)-0.5;
    vec2 id = floor(uv);
    vec2 cid = vec2(0.0);

    for(float y = -1.0; y <= 1.0; y++)
    {
        for(float x = -1.0; x <= 1.0; x++)
        {
            vec2 offs = vec2(x, y);

            vec2 n = h22(id+offs);
            vec2 p = offs+sin(n*t)*0.5;
            float d = length(gv-p);

            if(d<minDist)
            {
                minDist = d;
                cid = id+offs;
            }
        }
    }
    
    return minDist;
}

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,
                        0.366025403784439,
                        -0.577350269189626,
                        0.024390243902439);
    
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    
    vec2 i1 = vec2(0.0);
    i1 = (x0.x > x0.y)? vec2(1.0, 0.0):vec2(0.0, 1.0);
    vec2 x1 = x0.xy + C.xx - i1;
    vec2 x2 = x0.xy + C.zz;
    
    i = mod289(i);
    vec3 p = permute(
            permute( i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0 ));
    
    vec3 m = max(0.5 - vec3(
                        dot(x0,x0),
                        dot(x1,x1),
                        dot(x2,x2)
                        ), 0.0);
    
    m = m*m ;
    m = m*m ;
    
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0+h*h);
    
    vec3 g = vec3(0.0);
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * vec2(x1.x,x2.x) + h.yz * vec2(x1.y,x2.y);
    
    return 130.0 * dot(m, g);
}

float GetDist(vec3 p) {
    float v = -voronoi(p.xz*0.1, 100.0);
    v *= voronoi(p.xz*0.15*rot(3.141*0.125), 251.0);
    v *= voronoi(p.xz*0.2*rot(3.141*0.125), 529.0);
    v *= 0.75;
    v += 0.5;
    
    float pd = smoothstep(p.y, 0.0, v);
    
    return pd*p.y;
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

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-(0.5*resolution.xy))/resolution.y;
    vec4 col = vec4(0.0);
    
    float t = time*0.5;
    
    //Raymarching camera variables
    
    vec3 ro = vec3(0.0, 6.0, -10.0);
    vec3 rd = normalize(vec3(uv.x, uv.y-0.1, 1.0));
    rd.x += sin((uv.y*3.141*8.0)+(t*3.141))*0.02; //Heat distortion
    float no = ((snoise(rd.xx+t)*2.0)-1.0)*0.05;
    
    //Raymarching origin rotation
    
    ro.zx *= rot((t*3.141*0.125)+3.141); //Y axis rotation
    
    //Raymarching direction rotation
    
    rd.zy *= rot(sin(t*3.141*0.5)*3.141*0.01); //X axis rotation
    rd.xy *= rot(3.141*sin(t*3.141*0.2)*0.01); //Z axis rotation
    rd.zx *= rot((t*3.141*0.125)+3.141); //Y axis rotation
    
    //Raymarch processing
    
    float d = RayMarch(ro, rd);
    
    //Raymarch hit-point
    
    vec3 p = ro + rd * d;
    
    //Diffuse lighting, (Just ambience lighting)
    
    vec4 dif = vec4(0.7, 0.2, 0.0, 0.0);
    
    //Modifying color variable
    
    float fog = smoothstep(25.0, MAX_DIST, d);
    
    col = dif*smoothstep(1.0, 0.0, pow(p.y, 0.001))*300000.0; //Color depth; The lower, the darker; The higher, the brighter. This adds a lot of detail on the color.
    col = mix(col, vec4(0.8, 0.25, 0.1, 0.0), fog); //Add a little lovely fog effect in the background
    
    col.xyz += ((h22(uv.xy+t).x*2.0)-1.0)*0.05;
    col.xyz += no*fog*2.0;
    
    glFragColor = col;
}
