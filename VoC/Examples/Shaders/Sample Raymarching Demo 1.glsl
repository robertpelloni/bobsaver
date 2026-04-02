#version 420

// original https://www.shadertoy.com/view/3sBGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define MaxSteps 64.
#define MinDistance 0.01
#define eps 0.001

#define red vec3(227./255., 10./255., 4./255.)
#define yellow vec3(250./255., 169./255., 1./255.)

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

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

#define OCTAVES 4
float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 1.5;
        amplitude *= .5;
    }
    return value;
}

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

vec3 map(vec3 p) {
    mat3 rot = rotateZ(0.13*p.z);
    p *= rot;
    return fract(p) - 0.5;   
}

// Smooth min function from IQ
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float scene(vec3 p) {
    p = map(p);
    float outerSphere = sdSphere(p, .20);
    float box = sdBox(p, vec3(1,1,1)*.15) + 0.005*fbm(50.*p.xy);    
    return max(outerSphere, box);
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
    mat3 rot2 = rotateY(time*2.);
    vec3 L1 = shadeBlinnPhong(p, rd, sn, rot*vec3(5) + vec3(0,0,time*2.), 35., red);
    vec3 L2 = shadeBlinnPhong(p, rd, sn, rot2*vec3(-5) + vec3(0,0,time*2.), 20., yellow);
    
    vec3 ambient = vec3(.1);
    
    return L1 + L2 + ambient;
    
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    vec3 col = vec3(.0);
    vec3 ro = vec3(0,0,-5);
    vec3 rd = normalize(vec3(uv.x, uv.y, 0) - ro);
    mat3 rot = rotateZ(cos(time/4.));
    rd *= rot;

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
