#version 420

// original https://www.shadertoy.com/view/XlBXDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14
#define TAU 6.28318530718

const float MAT0 = 0.0;
const float MAT1 = 1.0;
const float MAT2 = 2.0;
const float MAT3 = 3.0;

float smin(float a, float b) {
    
    float k = 0.05;
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float noise(in vec2 uv) {
    return sin(1.5*uv.x)*sin(1.5*uv.y);
}

const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

float fbm(vec2 uv) {
    float f = 0.0;
    f += 0.5000*noise(uv); uv = m*uv*2.02;
    f += 0.2500*noise(uv); uv = m*uv*2.03;
    f += 0.1250*noise(uv); uv = m*uv*2.01;
    f += 0.0625*noise(uv);
    return f/0.9375;
}

float fbm2(in vec2 uv) {
   vec2 p = vec2(fbm(uv + vec2(0.0,0.0)),
                 fbm(uv + vec2(5.2,1.3)));

   return fbm(uv + 4.0*p);
}

float rand(in vec2 uv) {
    return fract(sin(dot(uv.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float voronoi(vec2 coord) {
    vec2 coordInt = floor(coord);
    vec2 coordFraction = fract(coord);
    
    float result = 8.0;
    for (int i = -1; i <= 1; i++)
        for (int j = -1; j <= 1; j++)
        {
             vec2 cellPoint = vec2(float(i), float(j));
            
            float offset = rand(coordInt + cellPoint);
            offset = 0.5 + 0.5*sin( time + 6.2831*offset );
            
            vec2 randomPoint = cellPoint + offset - coordFraction;
            float d = dot(randomPoint, randomPoint);
            
            result = min(result, d);
            
        } 
    return (sqrt(result));
}

vec2 add(in vec2 a, in vec2 b) {
 
    float mat;
    if(a.x < b.x) {
      mat = a.y;
    } else {
      mat = b.y;
    }
    
    return vec2(smin(a.x,b.x), mat);
}

vec2 sub(in vec2 a, in vec2 b) {
    
    float mat;
    if(a.x < b.x) {
      mat = b.y;
    } else {
      mat = a.y;
    }
    
    return vec2(max(a.x, b.x), mat);
}

vec3 rep(in vec3 p, in vec3 c) {
    vec3 q = mod(p,c)-0.5*c;
    return q;
}

vec2 rotate(in vec2 p, in float ang) {
    float c = cos(ang), s = sin(ang);
    return vec2(p.x*c - p.y*s, p.x*s + p.y*c);
}

vec2 torus(in vec3 p, in vec2 t, in float mat) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return vec2(length(q)-t.y, mat);
}

vec2 sphere(in vec3 p, in float r, in float mat) {
    return vec2(length(p) - r, mat);
}

vec2 plane(in vec3 p, in vec4 n, in float mat) {
  return vec2(dot(p,n.xyz) + n.w, mat);
}

vec2 cylinder(in vec3 p, in vec3 c, in float mat) {
  return vec2(length(p.xz-c.xy)-c.z, mat);
}

vec2 box(in vec3 p, in vec3 b, in float mat) {
  return vec2(
      length(
          max(abs(p)-b,0.0)
      ) * length(p*.05)
  , mat);
}

float map(in vec3 p, inout float mat) {
   
    vec2 scene = vec2(999.0, MAT0);

    float lp = length(p);
    
    vec2 s1 = box(p, vec3(.25), MAT0);

    scene = add(scene, s1);

    p = rep(p, vec3(.5));
    
    vec2 s = sphere(p, length(p) * .5, MAT1);
    scene = add(scene, s);
    
    mat = scene.y;
    
     return scene.x;
}

mat3 setLookAt(in vec3 ro, in vec3 ta,in float cr) {
    vec3  cw = normalize(ta-ro);
    vec3  cp = vec3(sin(cr), cos(cr),0.0);
    vec3  cu = normalize( cross(cw,cp) );
    vec3  cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

float softshadow(in vec3 ro, in vec3 rd, in float mint, in float tmax) {
    float res = 1.0;
    float t = mint;
    
    float mat = MAT3;
    for( int i = 0; i < 16; i++ ) {
        float h = map(ro + rd*t, mat);
        res = min( res, 4.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0*uv;
    p.x *= resolution.x / resolution.y;
    
    // camera    
    vec3 ro = vec3(
        -1.7*cos(time * .5),
        .0,
        1.7*sin(time * .5)
       );
    vec3 ta = vec3(0.0);
    float roll = 0.0;

    // camera tx
    mat3 ca = setLookAt( ro, ta, roll );
    vec3 rd = normalize( ca * vec3(p.xy,1.75) );

    float t = 0.001;    // Near
    float tmax = 120.0; // Far
       
    float h = 0.001;
    float hmax = 0.001;
    
    float mat = MAT0;
    
    vec3 c = vec3(0.0);
    vec3 ao = vec3(0.0);
    
    const int steps = 100;
    for(int i = 0 ; i < steps ; i++) {
        
        if(h < hmax || t > tmax ) {
            ao = vec3(1.0) - float(i)/float(steps);
            break;
        }
        
        h = map(ro + t *rd, mat);
        t += h;
    }
    
    if(t < tmax) {
        vec3 pos = ro+rd*t;
        
        vec2 r = vec2(0.001,0.0);
        vec3 nor = normalize(vec3(map(pos+r.xyy, mat)-map(pos-r.xyy, mat),
                                  map(pos+r.yxy, mat)-map(pos-r.yxy, mat),
                                  map(pos+r.yyx, mat)-map(pos-r.yyx, mat)));
          vec3 ref = reflect(rd,nor);
        
        if(mat == MAT0) {
          c = vec3(1.0,0.0,0.0);
        }
        
        if(mat == MAT1) {
          c = vec3(1.0); 
        }
        
        vec3 lig = vec3(0.5773);
        c *= softshadow(pos, lig, 0.03, 4.0);
        c *= clamp(dot(nor,lig), 0.1, 1.0);
        
        c *= 1.0 + clamp(dot(ref,lig), 0.0, .5) * .3;
        
        c *= 1.0 + ao * 20.;
        
        c += vec3(.1,.5,.9) * abs(pos.x * pos.y * pos.z) * .5 * length(1.0 / p * p);
        
        c = rgb2hsv(c);
        
        c.y *= 1.01;
        c.z *= 1.5;
        
        c.x += length(p) + fbm2(pos.xy) *.1;
        
        c = hsv2rgb(c);
    } 
    
    glFragColor = vec4(c,1.0);
}
