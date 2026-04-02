#version 420

// original https://www.shadertoy.com/view/3d23Wt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define MaxSteps 128.
#define MinDistance 0.001
#define eps 0.001
#define Iterations 24.
#define speed time
#define M ((2.*mouse*resolution.xy.xy-R)/R.y*4.)

#define red vec3(227./255., 10./255., 4./255.)
#define yellow vec3(250./255., 100./255., 1./255.)
#define salmon vec3(1., 227./255., 161./255.)
#define blue vec3(163./255.,228./255.,1.)
mat2 r2(float angle) { return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)); }

mat3 rotateX(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

mat3 rotateY(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}

mat3 rotateZ(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

// from IQ
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos(6.28318 * (c*t + d));
}

// from IQ
float sdCircle(vec2 p, float r) {
    return length(p) - r;    
}

// from IQ
float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

vec2 T(vec2 p) {

    vec4 w = vec4(0.0); //texture( iChannel0, vec2(15./256.,0.1));
    vec4 w2 = vec4(0.0); //texture( iChannel0, vec2(150./256.,0.1));
    float s = 0.0006 + 0.0005 * cos(time/2.);
    for(float i=0.; i < Iterations; i++) {
        p = abs(p) - s - i/Iterations; 
        p *= r2(3.1415*fract(time / 20.) + w.x/4.);
        p *= (i/Iterations*.4 + 1.);
    }
    
    return p;
}

float kaleidoscope(vec2 p) {
    float d = sdCircle(T(p), 0.5);
    return d;
}

float DE(vec3 z)
{
    mat3 ry = rotateY(time);
    mat3 rz = rotateZ(time / 2.);
    mat3 rot = ry * rz;
    
    //z *= rot;
    
    float Scale = 2.;
    float Offset = .3;
    float r;
    float n = 0.;
    while (n < Iterations) {
       //if(z.x+z.y<0.) z.xy = -z.yx; // fold 1
       //if(z.x+z.z<0.) z.xz = -z.zx; // fold 2
       //if(z.y+z.z<0.) z.zy = -z.yz; // fold 3    
        
       z = abs(z);
       float coef = (1. - n / Iterations);
        
       z *= rotateX(.3*cos(3.1415*2.*fract(time/20.)) );
       z *= rotateY(.3*cos(3.1415*2.*fract(time/20.)) );
       z *= rotateZ(.3*cos(3.1415*2.*fract(time/20.)) );
       z = z*Scale - Offset*(Scale-1.0) * (1. - n / Iterations);
       n++;
    }
    return (length(z) ) * pow(Scale, -float(n));
}

// from IQ
float sdSphere(vec3 p, float r) { return length(p) - r; }
float sdYPlane(vec3 p, float y) { return p.y - y; }

// from IQ
float sdBox(vec3 p, vec3 b) { 
    vec3 d = abs(p) - b;
    return length(max(d,0.0));
}

vec3 map(vec3 p) {
    
    
    
    return fract(p * rotateZ(0.2*p.z)) - 0.5;
    
    //mat3 rot = rotateZ(0.13*p.z);
    //p *= rot;
    float x = fract(p.x) - 0.5;
    float z = fract(p.z) - 0.5;
    
    return vec3(x, p.y, z);
}

// Smooth min function from IQ
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smoothstep2(float a, float b, float w, float v) {
    return smoothstep(a-w, a, v) - smoothstep(b, b+w, v);
}

float scale = .3;
vec2 scene(vec3 p) {
    p = map(p);
    
    p -= vec3(0,-0.4,0);
    
    float sphere = sdSphere(p, scale);
    
    float fractal = DE(p - vec3(0,.5,0));
    return vec2(fractal, 0);

    float plane = sdPlane(p, vec4(0., 1., 0., scale));
    int id = 0;
    if(fractal > plane) id = 1;
    return vec2(min(fractal, plane), id);
}

float shadowScene(vec3 p){
    //p = map(p);
    float fractal = DE(p - vec3(0,.5,0));
    return fractal;
}

vec3 calcNormal(vec3 p) {
    float h = 0.001;
    vec2 k = vec2(1,-1);
    vec3 n = normalize( k.xyy*scene( p + k.xyy*h ).x + 
                  k.yyx*scene( p + k.yyx*h ).x + 
                  k.yxy*scene( p + k.yxy*h ).x + 
                  k.xxx*scene( p + k.xxx*h ).x );    
    return n;
}
    
vec3 march(vec3 ro, vec3 rd) {
    float t = 0., i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        vec2 hit = scene(p);
        float dt = hit.x;
        float id = hit.y;
        t += dt;
        if(dt < MinDistance) {
            return vec3(t-MinDistance, id, 1.-i/MaxSteps);  
        }
    }
    return vec3(0.);
}

float marchShadow(vec3 ro, vec3 rd) {
    float t = 0., i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        float dt = shadowScene(p);
        t += dt;
        if(dt < MinDistance) {
            return t-MinDistance;    
        }
    }
    return 0.;
}

// https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model
vec3 shadeBlinnPhong(vec3 p, vec3 viewDir, vec3 normal, vec3 lightPos, float lightPower, vec3 lightColor) {
    vec3 diffuseColor = vec3(0.5);
    vec3 specColor = vec3(1);
    float shininess = 32.;

    vec3 lightDir = lightPos - p;
    float dist = length(lightDir);
    dist = dist*dist;
    lightDir = normalize(lightDir);
    
    float lambertian = max(dot(lightDir, normal), 0.0);
    float specular = .0;
    
    if(lambertian > 0.) {
        viewDir = normalize(-viewDir);
        
        vec3 halfDir = normalize(viewDir + lightDir);
        float specAngle = max(dot(halfDir, normal), .0);
        specular = pow(specAngle, shininess);
    }
    
    vec3 color = diffuseColor * lambertian * lightColor * lightPower / dist +
                 specColor * specular * lightColor * lightPower / dist;
    
       return color;
}

vec3 light(vec3 p, vec3 sn, vec3 rd) {
    
    vec3 top = shadeBlinnPhong(p, rd, sn, vec3(0,10,0) + vec3(0,0,speed), 50., vec3(.9));
    
    vec3 L1 = shadeBlinnPhong(p, rd, sn, vec3(5,-10,15) + vec3(0,0,speed), 30., vec3(.9,.9,.5));
    vec3 L2 = shadeBlinnPhong(p, rd, sn, vec3(-5,1,-10) + vec3(0,0,speed), 20., vec3(.8,.8,.3));
    
    
    vec3 ambient = vec3(.1);
    
    return L1 + L2 + ambient + top;
    
}

float checker(vec2 p, float scale) {
    p = trunc(fract(p)*scale);
    if(mod(p.x + p.y, 2.) == 0.) return 1.;
    return 0.;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    vec3 col = vec3(.0);
    vec3 ro = vec3(0,.3,-4);
    mat3 rot = rotateZ(-time/4.);
    
    vec3 rd = normalize(vec3(uv.x, uv.y, 0) - ro);
    
    rd *= rot;
    ro += vec3(0,-.15,speed);
    //ro *= rot;
    //rd *= rot;
    
    vec3 hit = march(ro, rd);
    float t = hit.x;
    float id = hit.y;
    
    if(t > eps) {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p);
        col = light(p, n, rd);
        
        // sphere
        if(id == 0.) {
            col *= hit.z;
        }
        
        // floor
        if(id == 1.) {
         
            vec3 checkerBoard = mix(vec3(0), vec3(1), checker(p.xz, 2.));
            col = mix(col, checkerBoard, 0.5) * hit.z;
        }
        
        float shadow = marchShadow(p + 0.1*n, normalize(vec3(10,10,10) - p));
        if(shadow > eps) {
            col = mix(col, vec3(0), .5);    
        }
        
        float fog = 1. / (0.3 + t * t * 0.05);
        col = mix(vec3(0), col, fog);
    }
    else {
        vec3 topcolor = vec3(127./255., 161./255., 189./255.);
        vec3 bottomcolor = vec3(84./255., 111./255., 138./255.);
        
        col = vec3(0);
    }

    glFragColor = vec4(col,1.0);
}
