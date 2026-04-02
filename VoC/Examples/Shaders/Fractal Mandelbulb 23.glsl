#version 420

// original https://www.shadertoy.com/view/WdfXRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define MaxSteps 64.
#define MinDistance 0.0007
#define eps 0.001

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
vec2 DE(vec3 pos) {
        
    float Iterations = 64.;
    float Bailout = 2.;
    float Power = 6. - 4.*cos(time/16.);
    
    vec3 trap = vec3(0,0,0);
    float minTrap = 1e10;
    
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for (float i = 0.; i < Iterations ; i++) {
        r = length(z);
        if (r>Bailout) break;
        
        minTrap = min(minTrap, z.z);
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        // convert back to cartesian coordinates
        //z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z = zr*vec3( cos(theta)*cos(phi), cos(theta)*sin(phi), sin(theta) );
        z+=pos;
    }
    return vec2(0.5*log(r)*r/dr, minTrap);
}

vec2 scene(vec3 p) {
    
    return DE(p - vec3(0,.1,0));
}

float shadowScene(vec3 p){
    return DE(p - vec3(0,.1,0)).x;
}

// from iq
vec3 calcNormal(vec3 p) {
    float h = 0.001;
    vec2 k = vec2(1,-1);
    vec3 n = normalize( k.xyy*scene( p + k.xyy*h ).x + 
                  k.yyx*scene( p + k.yyx*h ).x + 
                  k.yxy*scene( p + k.yxy*h ).x + 
                  k.xxx*scene( p + k.xxx*h ).x );    
    return n;
}

// ro: ray origin, rd: ray direction
// returns t and the occlusion as a vec2
vec3 march(vec3 ro, vec3 rd) {
    float t = 0., i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        vec2 hit = scene(p);
        float dt = hit.x;
        t += dt;
        if(dt < MinDistance) {
            return vec3(t-MinDistance, 1.-i/MaxSteps, hit.y);  
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

// p: point, sn: surface normal, rd: ray direction (view dir/ray from cam)
vec3 light(vec3 p, vec3 sn, vec3 rd) {
    vec3 top = shadeBlinnPhong(p, rd, sn, vec3(0,5,0), 20., vec3(.2));
    
    vec3 L1 = shadeBlinnPhong(p, rd, sn, vec3(5,-5,5), 30., vec3(.7));
    vec3 L2 = shadeBlinnPhong(p, rd, sn, vec3(5,-5,-5), 30., vec3(.4));
    vec3 L3 = shadeBlinnPhong(p, rd, sn, vec3(-5,-5,5), 30., vec3(.7));
    vec3 L4 = shadeBlinnPhong(p, rd, sn, vec3(-5,-5,-5), 30., vec3(.4));
    
    vec3 ambient = vec3(.1);
    return L1 + L2 + L3 + L4 + ambient + top;
}

// https://iquilezles.org/www/articles/palettes/palettes.htm
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos(6.28318 * (c*t + d));
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    vec3 col = vec3(.0);
    vec3 ro = vec3(0,0,-3); // ray origin
    vec3 rd = normalize(vec3(uv.x, uv.y, 0) - ro); // ray direction
    
    mat3 rot = rotateX(time / 8.) * rotateZ(time / 8.) * rotateZ(time/4.);
    
    ro -= vec3(0,0,1.);
    ro *= rot;
    rd *= rot;
    
    vec3 hit = march(ro, rd); // returns t and the occlusion value 
    float t = hit.x;
    
    if(t > eps) {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p);
        
        float trap = fract(hit.z*.5 + .5);
        col = pal(trap, vec3(.5), vec3(0.5), 
                   vec3(1.0,1.0,1.0), vec3(.0, .10, .2));
        
        col *= .2;
        
        col += light(p, n, rd);
        col *= hit.y;   // occlusion 
        
        float shadow = marchShadow(p + 0.1*n, normalize(vec3(10,10,10) - p));
        if(shadow > eps) {
            col = mix(col, vec3(0), .1);    
        }
        
        float fog = 1. / (0.1 + t * t * 0.03);
        col = mix(vec3(0), col, fog);
    }
    else {
        vec3 topcolor = vec3(127./255., 161./255., 189./255.);
        vec3 bottomcolor = vec3(84./255., 111./255., 138./255.);
        col = mix(bottomcolor, topcolor, uv.y);
        col = vec3(0);
    }

    glFragColor = vec4(col,1.0);
}
