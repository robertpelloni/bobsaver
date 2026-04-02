#version 420

// original https://www.shadertoy.com/view/3dfcD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 sky(vec3 rd) {
  float n = max(0., rd.y);
  n +=1.0;
  return mix(vec3(1.0), vec3(0.7, 0.8, 0.9), n);
}

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float noise21 (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float fbm21 ( in vec2 _st) {
    float v = 0.0;
    float a = 0.6;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < 5; ++i) {
        v += a * noise21(_st+time*0.1);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float mixfbm(vec2 p){
    vec2 q = vec2( fbm21( p + vec2(0.0,0.0) ),
                   fbm21( p + vec2(5.2,1.3) ) );

    vec2 r = vec2( fbm21( p + 4.0*q + vec2(1.7,9.2) ),
                   fbm21( p + 4.0*q + vec2(8.3,2.8) ) );

    //return fbm21( p + 4.0*r );
    return fbm21(q);
}

//////////

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 33.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float fbm(vec3 x) {
    
    float v = 0.0;
    float a = 1.0;
    vec3 shift = vec3(100);
    for (int i = 0; i < 5; ++i) {
        v += a * noise(x);
        x = x * (1.0) + shift;
        a *= 0.5;
    }
    return v;
}

////////

vec3 twist(vec3 p, float power){
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    mat3 m = mat3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return m * p;
}

vec3 twistX(vec3 p, float power){
    float s = sin(power * p.x);
    float c = cos(power * p.x);
    mat3 m = mat3(
        1.0, 0.0, 0.0,
        0.0,   c,   s,
        0.0,  -s,   c
    );
    return m * p;
}

/////
float distPlane(in vec3 p, vec4 n)
{
    return dot(p, n.xyz) + n.w;
}

vec4 plane = vec4(0.0, 0.8, 0.0, 0.8);

float distHeight(in vec3 p)
{
    float d = distPlane(p, plane);
    //float tex = texture(iChannel0, mod(p.xz * 0.2, 1.0));
    float tex = mixfbm(p.xz);
    tex *= 1.0;
    return  d- tex;
}

/////

float sphere_d(vec3 pos, float s){
    
    return length(pos) - s;
}

float box_d(vec3 pos, vec3 size){
    vec3 q = abs(pos) - size;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float smin(float d1, float d2, float k ){
    float res = exp(-k * d1) + exp(-k * d2);
    return -log(res) / k;
}

float object_d(vec3 pos){
    //vec3 p = mod(pos, 4.0) - 2.0;
    vec3 move =  vec3(0.0, 4.0, 0.0);
    vec3 twistpos = twist(pos - move, 0.2+ (0.1+0.5*sin(time*0.5)));
    twistpos = twistX(pos - move , 0.2+(0.1+0.5*cos(time*0.5)));
  
    //float n =  length(fbm(pos)-.15+sin(time)*.05 )-.1;
    float n = sphere_d(twistpos, 4.5)+fbm(twistpos);
    float m = distHeight(pos);
    n = min(n,m);
    return  n; 
}

    
vec3 getNormal(vec3 pos){
    float d = 0.001;
    return normalize(vec3(
        object_d(pos + vec3(  d, 0.0, 0.0)) - object_d(pos + vec3( -d, 0.0, 0.0)),
        object_d(pos + vec3(0.0,   d, 0.0)) - object_d(pos + vec3(0.0,  -d, 0.0)),
        object_d(pos + vec3(0.0, 0.0,   d)) - object_d(pos + vec3(0.0, 0.0,  -d))
    ));
}

struct Ray {
    vec3 pos;
    vec3 dir;
};
    
    
mat3 x_axis_rot(float angle){
    float c = cos(angle);
    float s = sin(angle);
    return mat3(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c); 
 
}

mat3 y_axis_rot(float angle){
    float c = cos(angle);
    float s = sin(angle);
    return mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0,  c);
}
    
    
    
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 pos = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 color = vec3(0.0);
    
    vec2 mouse_pos =  (mouse*resolution.xy.xy/resolution.xy-.5) * 2.;
    
    
    
    vec3 camera_pos = vec3(0.0, 0.5, -10.0);
    vec3 camera_up = vec3(0.0, 1.0, 0.0);
    vec3 camera_dir = vec3(0.0, 0.0, 1.0);
    vec3 camera_side = cross(camera_up, camera_dir);
    
    Ray ray;
    ray.pos = camera_pos;
    ray.dir = normalize(pos.x * camera_side + pos.y * camera_up + camera_dir);
    
    mat3 rot = x_axis_rot(0.0) * y_axis_rot(0.0);
    
    
    float t = 0.0, d;
    float b = 0.0;
    for(int i = 0; i < 128; i++){
        d = object_d(rot*ray.pos);
        
        if (d < 0.001){
            break;
        }
        t += d;
        ray.pos = camera_pos + t*ray.dir;
        b += 1./100.;
    } 
    
    
    vec3 light_dir = normalize(vec3(-1.0, 1.0 , -1.0));
    vec3 light2_dir = normalize(vec3(1.0, -1.0 , 1.0));
    vec3 normal = getNormal(rot*ray.pos);
    
    float L = dot(normal, light_dir);
    float L2 = dot(normal, light2_dir);
    
    
   
    L = max(L, L2);  ///maxにすると良い
    
    
    
    //b = pow(b,2.0);
    //L = min(b,L);
    vec3 blue = vec3(0.1, 0.3, 0.8)*4.0;
    vec3 green = vec3(0.0, 0.05, 0.1);
    vec3 b3 = b* blue;
    
    
    if(d < 0.001){
        color = max(vec3(L*0.0), b3);;
    } else{
        color =sky(ray.dir);
    }
    
    
    
    glFragColor = vec4(color,1.0);
}
