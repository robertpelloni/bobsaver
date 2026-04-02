#version 420

// original https://www.shadertoy.com/view/ws2Gzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS .001
#define STEPS 120
#define FAR_CLIP 100.0
vec2 cossin(float f){ return vec2(cos(f), sin(f)); }
vec2 rotate(vec2 xy, float f) {
    vec2 cs = cossin(f);
    return mat2x2(cs.x, -cs.y, cs.y, cs.x) * xy;
}
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float opUnion( float d1, float d2 ) { return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

mat2x2 rotate(float t) { 
    float c = cos(t);
    float s = sin(t);
    return mat2(c,-s,s,c);
}

struct SDF_RESULT {
    vec4 params;
    float best_dist;
    int id;
} sdf_result;

struct CAST_RESULT {
    vec3 ro;
    vec3 rd;
    vec3 end;
    float total_dist;
    bool hit;
} cast_result;

bool update(float dist) {
    if(dist < sdf_result.best_dist) {
        sdf_result.best_dist = dist;
        return true;
    }
    return false;
}

vec3 mirror(vec3 vin, vec3 pos, vec3 norm) {
    //  v = i - 2 * n * dot(i n) .
    float d = dot((vin - pos), norm);
    return pos + (
        (vin - pos) - (1.0+sign(d)) * norm * d
    );
    return reflect(vin-pos, norm)+pos;
}
float sdf(vec3 pos) {
    sdf_result.best_dist = FAR_CLIP;
    sdf_result.id = -1;
    
    if(update(length(pos.yz)-.1)) {
        sdf_result.params.xyz = vec3(1,0,0);
    }
    if(update(length(pos.xz)-.1)) {
        sdf_result.params.xyz = vec3(0,1,0);
    }
    if(update(length(pos.xy)-.1)) {
        sdf_result.params.xyz = vec3(0,0,1);
    }
    
    
    for(float r = 10.0 ; r > 0.0 ; r--) {
        
        pos = pos.zxy;
        
        float bigR = .9 + r*.2;
        float littleR = .1;
        
        pos.xy = pos.xy*rotate(time*.1);
        
        vec3 pos2 = pos;
        pos2.xz = pos2.xz * rotate(time * r*.1);
        if(update(
            opIntersection(
                sdTorus(pos2, vec2(bigR, littleR)),
                sdBox(pos2, vec3(bigR+littleR,littleR,(bigR+littleR)*mix(.5,.2,sin(time*r*.1))))
            )
        )) {
            sdf_result.params.xyz = abs(cos(vec3(1,1.1,1.5)*r));
        }
        
        
    }
    
    return sdf_result.best_dist;
}

vec2 eps = vec2(EPS, 0);
vec3 sdf_normal(vec3 pos) {
    return normalize(vec3(
        sdf(pos - eps.xyy)-sdf(pos + eps.xyy),
        sdf(pos - eps.yxy)-sdf(pos + eps.yxy),
        sdf(pos - eps.yyx)-sdf(pos + eps.yyx)));
}

vec3 color() {
    return sdf_result.params.xyz;
}

vec3 lighting() {
    float f = cast_result.total_dist/FAR_CLIP;
    vec3 n = sdf_normal(cast_result.end);
    return vec3(1.0-sqrt(f)) * dot(cast_result.rd, n);
}

void cast_ray(vec3 ro, vec3 rd) {
    
    cast_result.ro = ro;
    cast_result.rd = rd;
    cast_result.hit = false;
    
    vec3 pos = ro;
    float total_dist = 0.0;
    for(int i = 0 ; i < STEPS ; i ++) {
        float dist = sdf(pos);
        if(dist < eps.x) {
            cast_result.hit = true;
            break;
        }
        
        total_dist += dist;
        pos += dist * rd;
        
        if(total_dist > FAR_CLIP) {
            total_dist = FAR_CLIP;
            break;
        }
    }   
    
    cast_result.total_dist = total_dist;
    cast_result.end = pos;
}

vec3 movement(vec3 i) {
   
    i.xz = i.xz * rotate(cos(time)*.2);
    i.xy = i.xy * rotate(time*.5);
     return i;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;
    
    vec3 ro = movement(vec3(-5, 0, 0));
    
    vec3 rd = movement(normalize(vec3( 1.8, uv)));
    
    cast_ray(ro, rd);
    
    
    glFragColor.rgb = color() * lighting();
    
    
}
