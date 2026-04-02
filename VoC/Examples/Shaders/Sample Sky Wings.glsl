#version 420

// original https://neort.io/art/bvumr6s3p9f30ks57qd0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float FOCUS = 0.8;
const float REFRACTION = 0.9;
const vec3 LIGHTDIR = vec3(0.0, 0.3, 0.3);

float mosaicGrass(vec2 p){
    return length(tan(p*FOCUS)*REFRACTION);
}

vec3 repeat(vec3 p){
    return mod(sin(p),0.189);
}

mat2 rotate(float t){
     return mat2(cos(t),sin(t),-sin(t),cos(t));   
}

float sphere(vec3 p,float size){
     return length(p) - size;   
}

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 
}

float Wings(vec3 p){
    float d;
    vec3 newP;
    newP = repeat(p);
    d = sphere(newP,0.13);
     return d;
}

float obj(vec3 p){
    float d;
    p.xy *= rotate(time);
    p.yz *= rotate(time);
    d = sdOctahedron(p,0.2);
     return d;
}

vec3 getNormal(vec3 p){
    float d = 0.0001;
    return normalize(vec3(
        obj(p + vec3(  d, 0.0, 0.0)) - obj(p + vec3( -d, 0.0, 0.0)),
        obj(p + vec3(0.0,   d, 0.0)) - obj(p + vec3(0.0,  -d, 0.0)),
        obj(p + vec3(0.0, 0.0,   d)) - obj(p + vec3(0.0, 0.0,  -d))
    ));
}

float mainDist(vec3 p1,vec3 p2){
    float a,b,d;
    a = Wings(p1);
    b = obj(p2);
    d = min(a,b);
     return d;
}

void main(void) {
    vec2 uv1 = vec2(abs(gl_FragCoord.x * 2.0 - resolution.x),(gl_FragCoord.y * 2.0 - resolution.y)) / vec2(resolution.x, resolution.y);
    vec2 uv2 = (gl_FragCoord.xy * 2.0 - resolution.xy)/min(resolution.x, resolution.y);
    vec3 cd = vec3(0.0,0.0,-0.8);
    vec3 cu = vec3(0.0,1.0,0.0);
    vec3 cs = cross(cd,cu);
    float td = 4.0;
    vec3 ray1 = normalize(cs * uv1.x + cu * uv1.y + cd * td);
    vec3 ray2 = normalize(cs * uv2.x + cu * uv2.y + cd * td);
    
    float d,t = 0.0;
    
    vec3 rp1 = vec3(4.0,sin(time+mosaicGrass(uv1)),-time*0.9);
    vec3 rp2 = vec3(0.0,0.0,2.0);
    
    for(int i = 0; i < 64; i++){
         d = mainDist(rp1 + ray1 * t,rp2 + ray2 * t);
        if(d < 0.001){
            break;
        }
        t += d;
    }
    
    vec3 color1,color2;
    if(abs(d) < 0.001){
        vec3 normal2 = getNormal(rp2 + ray2 * t);
        float diff2 = clamp(dot(LIGHTDIR, normal2), 0.1, 1.0);
        color1 = vec3(1.0, 1.0, 1.0) * diff2;
    }else{
        color1 = vec3(0.2);
    }
    
    color2 = vec3(exp(-0.2*t),0.75,0.9);
    
    vec3 color = mix(color1,color2,0.9)*1.2;
    
    glFragColor = vec4(color,1.0);
}
