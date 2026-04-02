#version 420

// original https://www.shadertoy.com/view/tdBGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define MaxSteps 64.
#define MinDistance 0.01
#define eps 0.001

#define red vec3(227./255., 10./255., 4./255.)
#define yellow vec3(250./255., 100./255., 1./255.)

mat3 rotateY(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

mat3 rotateZ(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

float sdSphere(vec3 p, float r) { return length(p) - r; }
float sdYPlane(vec3 p, float y) { return p.y - y; }
float sdBox(vec3 p, vec3 b) { 
    vec3 d = abs(p) - b;
    return length(max(d,0.0));
}
// from IQ
float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

vec3 map(vec3 p) {
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

float scene(vec3 p) {
    p = map(p);
    float outerSphere = sdSphere(p - vec3(0,-0.5,0), .20); 
    
    float plane = sdPlane(p - vec3(0,0,0), normalize(vec4(0,1,0,0.5)));
    float yPlane = sdYPlane(p, -0.5);
    
    mat3 ry = rotateY(3.*p.y);
    float box = sdBox(ry*p, vec3(.05, 1, .05));
    
    
    yPlane = min(yPlane, box);
    
    return smin(yPlane, outerSphere, 0.15);
}

vec3 calcNormal(vec3 p) {
    float h = 0.0001;
    vec2 k = vec2(1,-1);
    vec3 n = normalize( k.xyy*scene( p + k.xyy*h ) + 
                  k.yyx*scene( p + k.yyx*h ) + 
                  k.yxy*scene( p + k.yxy*h ) + 
                  k.xxx*scene( p + k.xxx*h ) );    
    return n;
}
    
float march(vec3 ro, vec3 rd) {
    float t = 0., i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        float dt = scene(p);
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
    float shininess = 16.;

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
       
    mat3 rot = rotateY(time);
    mat3 rot2 = rotateY(time);
    vec3 L1 = shadeBlinnPhong(p, rd, sn, rot*vec3(5) + vec3(0,0,time*2.), 35., red);
    vec3 L2 = shadeBlinnPhong(p, rd, sn, rot2*vec3(-5, 5, -5) + vec3(0,0,time*2.), 20., yellow);
    
    vec3 ambient = vec3(.1);
    
    return L1 + L2 + ambient;
    
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    vec3 col = vec3(.0);
    vec3 ro = vec3(0,1,-5);
    vec3 rd = normalize(vec3(uv.x, uv.y, 0) - ro);
    mat3 rot = rotateY(cos(time/8.));
    //rd *= rot;

    ro += vec3(0,0,time*2.);
    float t = march(ro, rd);
    
    if(t > eps) {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p);
        col = light(p, n, rd);
        float fog = 1. / (1. + t * t * 0.02);
        col = mix(vec3(0), col, fog);
        //col = n*.5+.5;
    }

    glFragColor = vec4(col,1.0);
}
