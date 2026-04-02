#version 420

// original https://www.shadertoy.com/view/ltGSWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define distfar 6.0
#define iterations 5.0

float maxcomp(vec3 p) {
    return max(p.x,max(p.y,p.z));
}

float sdBox( vec3 p, vec3 b )
{
  vec3  di = abs(p) - b;
  float mc = maxcomp(di);
  return min(mc,length(max(di,0.0)));
}

float sdBox2D(vec2 p, vec2 b) {
    vec2  di = abs(p) - b;
    float mc = max(di.x,di.y);
    return min(mc,length(max(di,0.0)));
}

float sdCross( in vec3 p )
{
  float da = sdBox2D(p.xy,vec2(1.0));
  float db = sdBox2D(p.yz,vec2(1.0));
  float dc = sdBox2D(p.zx,vec2(1.0));
  return min(da,min(db,dc));
}

vec2 map(vec3 p) {
    float d = sdBox(p,vec3(1.0));
    
    for (float i = 0.0; i < iterations; i++) {

        float scale = pow(3.0,i);
        vec3 q = mod(scale*p,2.0)-1.0;
        q = 1.0-abs(q);
        float c = sdCross(q*3.0)/(scale*3.0);
        d = max(d,-c),1.0;
        
        p += scale/3.0;
        
    }
    
    return vec2(d,1.0);
    
}

vec3 calcnormal(vec3 p) {
    vec2 e = vec2(0.0001, 0.0);
    vec3 n;
    n.x = map(p+e.xyy).x - map(p-e.xyy).x;
    n.y = map(p+e.yxy).x - map(p-e.yxy).x;
    n.z = map(p+e.yyx).x - map(p-e.yyx).x;
    return  normalize(n);
}

float softshadow (vec3 ro, vec3 rd) {
    float res = 1.0;
    float t = 0.001;
    for (float i = 0.0; i < 1000.0; i++) {
        if (t>distfar) break;
        vec2 h = map(ro + t*rd);
        if (h.x < 0.0001) return 0.0;
        res = min(res, 64.0*h.x/t);
        t += h.x;
    }
    return res;
}

vec3 trace(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (float i = 0.0; i < 1000.0; i++) {
        if (t > distfar) break;
        vec2 d = map(ro + rd*t);
        if (d.x < 0.0001) return vec3(t, d.y, i);
        t += d.x;
    }
    return vec3(0.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x/resolution.y;
    
    vec3 ro = vec3(0.0,0.0,3.0);
    vec3 rd = normalize(vec3(uv,-1.5));
    
    float theta = sin(time/2.0);
    mat2 rot = mat2(cos(theta),sin(theta),-sin(theta),cos(theta));
    ro.yz *= rot;
    rd.yz *= rot;
    theta = time/3.0;
    rot = mat2(cos(theta),sin(theta),-sin(theta),cos(theta));
    ro.xz *= rot;
    rd.xz *= rot;
    
    vec3 t = trace(ro, rd);
    
    vec3 col = vec3(0.8);
    
    if (t.y > 0.5) {
        
        vec3 pos = ro + rd*t.x;
        vec3 lig = normalize(vec3(0.6,1.0,0.8));
        vec3 nor = calcnormal(pos);
        float refRange = 0.2;
        
        float occ = 1.0/(1.0+t.z/15.0);
        float sha = softshadow(pos, lig);
        float dif = max(0.0, dot(nor,lig));
        float sky = 0.5+0.5*nor.y;
        float ind = max(0.0, dot(nor,vec3(-1.0,-0.2,-1.0)*lig));
        float ref = max(1.0-refRange,dot(-nor,rd))-1.0+refRange;
        
        col = vec3(0.8,1.0,1.2)*dif*pow(vec3(sha),vec3(1.0,1.2,1.5));
        col += vec3(0.2,0.3,0.4)*ind*occ;
        col += vec3(0.2,0.2,0.3)*sky*occ;
        col += pow(ref,2.0)*4.0*occ;
        
        col = pow(col,vec3(0.4545));
        
    }
    
    glFragColor = vec4(col,1.0);
}
