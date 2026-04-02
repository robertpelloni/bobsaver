#version 420

// original https://www.shadertoy.com/view/XtyyDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Author: Anton Mikhailov
//This work is licensed under a Creative Commons Attribution 4.0 International License.

#define PI 3.14159265359
#define TAU (2.0*PI)

vec4 quat(vec3 axis, float angle) { return vec4(axis*sin(angle*0.5), cos(angle*0.5)); }
vec4 quat_i() { return vec4(0,0,0,1); }
vec4 quat_conj(vec4 q) { return vec4(-q.xyz,q.w); }
vec4 quat_mul(vec4 a, vec4 b) { return vec4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz)); }
vec3 quat_mul(vec4 q, vec3 v) { return v-2.0*cross(cross(q.xyz,v)-q.w*v,q.xyz); }

float hash(vec2 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return -1.0+2.0*fract( p.x*p.y*(p.x+p.y) );
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

float noise( in float p )
{
    return noise(vec2(p, 0.0));        
}

float hash(vec3 p)  // replace this by something better
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float luma(vec3 c) {
    return c.r*0.2 + c.g*0.7 + c.b*0.1;
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

float sdSphere(vec3 pos, float rad) {
    return length(pos) - rad;
}
float sdFloor(vec3 pos) {
    return pos.y;
}
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float smin(float a, float b, float k) {
    float x = exp(-a*k) + exp(-b*k);
    return -log(x)/k;
}
float wave() {
    return (1.0 + sin(time))*0.5;
}
void repeat(inout vec3 pos, float s) {
    pos.xz = mod(pos.xz, s)-s*0.5;
}
float field(vec3 pos) {
    float f = 10000.0;

    f = min(f, sdFloor(pos - vec3(0,-1,0)));
    f = min(f, sdBox(pos, vec3(1.0)));
    //f = min(f, sdSphere(pos, 1.0));
       //f = min(f, sdCappedCylinder(pos.xzy, vec2(1,1)));
    
    return f;
}

float trace(vec3 ray_ori, vec3 ray_dir,
            float t_min, float t_max,
            int max_iter) {
    
    float t = t_min;
    for (int i = 0; i < max_iter; ++i) {
        vec3 pos = ray_ori + ray_dir*t;
        float f = field(pos);
        if (f < 0.001) return t;
        if (t > t_max) return -1.0;
        t += f;
    }
    return -2.0;
}

vec3 shade(vec3 pos, vec3 nor, vec3 sur_col,
           vec3 lig_dir, vec3 lig_col,
           vec3 vie) {
    float ndotl = max(0.0, dot(nor,lig_dir));
    float vdotr = max(0.0, dot(vie,reflect(lig_dir,nor)));
    vec3 dif = sur_col * lig_col;
    vec3 spe = lig_col * vdotr*0.5;
    vec3 amb = sur_col*lig_col*0.03;
    
    float t = trace(pos,lig_dir, 0.1,5.0,50);
    float sdw = t > 0.0 ? 0.0 : 1.0;
    dif *= sdw;
    spe *= sdw;
    return sur_col;
    //return (dif+spe) * ndotl + amb;
    //return (nor+1.0)*0.5;
}

vec3 normal(vec3 pos) {
    float e = 0.001;
    vec3 n;
    n.x = (field(pos+vec3(e,0,0)) - field(pos-vec3(e,0,0)))/(2.*e);
    n.y = (field(pos+vec3(0,e,0)) - field(pos-vec3(0,e,0)))/(2.*e);
    n.z = (field(pos+vec3(0,0,e)) - field(pos-vec3(0,0,e)))/(2.*e);
    return n;
}

vec3 texture_wood(vec3 pos) {
    pos = quat_mul(quat(vec3(1,0,0),-0.0), pos);
       //pos.z -= 1.0;
    vec2 core = vec2(cos(pos.z), sin(pos.z))*0.1;
    pos.xy -= core;
    
    float r = length(pos.xy);
    float a = (TAU/2.0 + atan(pos.x,pos.y)) / TAU;
    
    float r_noise = noise(vec2(cos(a*TAU*2.0), sin(a*TAU*2.0)));
    r_noise += noise(vec2(10.0) + vec2(cos(a*TAU*4.0), sin(a*TAU*4.0))) * 0.5; // squigglyness
    r_noise += noise(vec2(100.0) + vec2(cos(a*TAU*8.0), sin(a*TAU*8.0))) * 0.4; // squigglyness
    r_noise += noise(vec2(1000.0) + vec2(cos(a*TAU*16.0), sin(a*TAU*16.0))) * 0.2; // squigglyness
    
    r_noise += noise(pos.z*0.5)*3.0; // knottyness
    
    r_noise *= noise(r*3.0)*5.0; // whorlyness
    r += r_noise*0.05*clamp(r,0.0,1.0); // scale and reduce at center
    
    vec3 col = vec3(1.0,0.8,0.35);
    //float c = 0.5 + 0.5*sin(r*100.0); // 100 rings per meter ~ 1cm rings
    float c = fract(r*5.0);
    //c = smoothstep(0.0,1.0, c/0.15) * smoothstep(1.0,0.0, (c-0.15)/0.85);
    c = smoothstep(0.0,1.0, c/0.15) * smoothstep(1.0,0.0, sqrt(clamp((c-0.15)/0.85,0.0,1.0)));
    //c = smoothstep(0.0,1.0, c/0.15) * smoothstep(1.0,0.0, pow(clamp((c-0.15)/0.85,0.0,1.0), 0.25));
    col = mix(col, vec3(0.5,0.25,0.1)*0.4, c); // ring gradient
    col = mix(col, col*0.8, noise(r*20.0)); // ring-to-ring brightness
    
    return col;
}

vec3 material(vec3 pos) {
    vec3 P = pos;
    if (pos.y < -0.99) {
        
         
        float s = 6.0;
        pos.z /= s;
        vec2 f = floor(pos.xz);
        pos.z += mod(f.x, 2.0)*0.5;
        f = floor(pos.xz);
        vec2 c = fract(vec2(pos.x,pos.z));
        c = (c-0.5)*2.0;
        c.y *= s;
       
        vec2 b = vec2(1.0,s);
        vec2 d = abs(c) - b;
         float l = min(max(d.x,d.y),0.0);
        l = smoothstep(0.0,0.05, -l)*0.9 + 0.1;
        //return vec3(l);
        //return abs(vec3(f.x,f.y,0)*0.1);
        //vec3 w = texture_wood(pos + vec3(sin(f.x),sin(f.y),f.y));
        //vec3 w = texture_wood(pos+vec3(0,sin(time),0));
        float idx = f.y*10.0+f.x*10.0;
        vec3 w = texture_wood(vec3(c.x,0,c.y) + vec3(vec2(cos(idx*0.1),sin(idx*0.1))*sin(idx),idx));
        //w = mix(w, vec3(luma(w)), mix(0.2, 0.4, 0.5+0.5*noise(f)));
        w = mix(w, vec3(0.7), mix(0.2, 0.4, 0.5+0.5*noise(f)));
        w *= mix(0.7, 1.0, 0.5+0.5*noise(f));
        //return vec3(mod(f.x, 2.0));
        return w * l;
        //float l = length(c);
        //return texture_wood(pos + vec3(f.x,f.y*3.0,f.x)*10.0);
        //return vec3(0,0,f.y/10.0);
        //return vec3(c.x,c.y,f.x/10.0);
    } else {
        return texture_wood(pos);
    }
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = (uv - 0.5)*2.0;
    float aspect = resolution.x/resolution.y;
    uv.x *= aspect;
    
    float elev = TAU/10.0;//TAU/12.0;
    //float azim = -TAU/12.0;
    float azim = sin(time)*TAU/32.0;//-TAU/12.0;
    vec4 rot = quat(vec3(1,0,0), elev);
    rot = quat_mul(rot, quat(vec3(0,1,0), azim));
    vec3 ray_ori = quat_mul(rot, vec3(0,0,3));
    vec3 ray_dir = quat_mul(rot, normalize(vec3(uv,-1.0)));
    
    vec3 col = vec3(1.0,0.8,0.3);
    
    const float near = 0.1;
    const float far = 10.0;
    
    float t = trace(ray_ori, ray_dir, near, far, 100);
    if (t > 0.0) {
        vec3 pos = ray_ori + ray_dir*t;
        vec3 nor = normal(pos);
        vec3 sur_col = material(pos);
        vec3 lig_col = vec3(1.0,0.9,0.85);
        vec3 lig_dir = normalize(vec3(1,1,1));
        col = shade(pos, nor, sur_col, lig_dir, lig_col, ray_dir);
    }
    else if (t == -2.0) col = vec3(1,0,1);
    
    glFragColor = vec4(pow(col,vec3(1.0/2.2)), 1.0);
}
