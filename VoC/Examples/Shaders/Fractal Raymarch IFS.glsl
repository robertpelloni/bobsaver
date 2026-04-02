#version 420

// original https://www.shadertoy.com/view/3djGDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define MaxSteps 32.
#define MinDistance 0.01
#define eps 0.001
#define Iterations 22.

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

// http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-iii-folding-space/
float DE(vec3 z)
{
    float angl = cos(time)*.2;
    mat3 rx = rotateX(angl);
    mat3 ry = rotateY(angl);
    mat3 rz = rotateZ(angl);
    mat3 rot = rx * ry * rz;
 
    float Scale = 2. + cos(time/8.);
    float Offset = .65;
    float n = 0.;
    while (n < Iterations) {
       z = abs(z);
       if(z.x - z.y < 0.) z.xy = z.yx;
       if(z.x - z.z < 0.) z.xz = z.zx;
       if(z.y - z.z < 0.) z.yz = z.zy;
       z *= rot;
       z = abs(z);
       z = z*Scale - vec3(vec3(Offset*(Scale-1.0)).xy, 0);
       n++;
    }
    return (length(z) ) * pow(Scale, -float(n));
}

float scene(vec3 p) {
    return DE(p - vec3(0,.1,0));
}

float shadowScene(vec3 p){
    return DE(p - vec3(0,.1,0));
}

// from iq
vec3 calcNormal(vec3 p) {
    float h = 0.001;
    vec2 k = vec2(1,-1);
    vec3 n = normalize( k.xyy*scene( p + k.xyy*h ) + 
                  k.yyx*scene( p + k.yyx*h ) + 
                  k.yxy*scene( p + k.yxy*h ) + 
                  k.xxx*scene( p + k.xxx*h ) );    
    return n;
}

// ro: ray origin, rd: ray direction
// returns t and the occlusion as a vec2
vec2 march(vec3 ro, vec3 rd) {
    float t = 0., i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        float dt = scene(p);
        t += dt;
        if(dt < MinDistance) {
            return vec2(t-MinDistance, 1.-i/MaxSteps);  
        }
    }
    return vec2(0.);
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

// p: point, sn: surface normal, rd: ray direction (view dir/ray from cam)
vec3 light(vec3 p, vec3 sn, vec3 rd) {
    vec3 top = shadeBlinnPhong(p, rd, sn, vec3(0,5,0), 30., vec3(.9));
    vec3 L1 = shadeBlinnPhong(p, rd, sn, vec3(5,-5,10), 30., vec3(.9,.9,.5));
    vec3 L2 = shadeBlinnPhong(p, rd, sn, vec3(-5,1,-5), 20., vec3(.8,.8,.3));
    vec3 ambient = vec3(.1);
    return L1 + L2 + ambient + top;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    vec3 col = vec3(.0);
    vec3 ro = vec3(0,2.,-4); // ray origin
    vec3 rd = normalize(vec3(uv.x, uv.y, 0) - ro); // ray direction
    
    mat3 rot = rotateY(-time/4.);
    ro *= rot;
    rd *= rot;
    
    vec2 hit = march(ro, rd); // returns t and the occlusion value 
    float t = hit.x;
    
    if(t > eps) {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p);
        col = light(p, n, rd);
        col *= hit.y;   // occlusion 
        
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
        col = mix(bottomcolor, topcolor, uv.y);
    }

    glFragColor = vec4(col,1.0);
}
