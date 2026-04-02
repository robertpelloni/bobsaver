#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rotatey(in vec3 p, float ang)
{
    return vec3(p.x*cos(ang)-p.z*sin(ang),p.y,p.x*sin(ang)+p.z*cos(ang)); 
}
vec3 rotatex(in vec3 p, float ang)
{
    return vec3(p.x,p.y*cos(ang)-p.z*sin(ang),p.y*sin(ang)+p.z*cos(ang)); 
}
vec3 rotatez(in vec3 p, float ang)
{
    return vec3(p.x*cos(ang)-p.y*sin(ang),p.x*sin(ang)+p.y*cos(ang),p.z); 
}

float scene(in vec3 p)    
{
    //p.x = mod(p.x+0.5, 1.0) - 0.5; 

    p = rotatey(p, p.y*sin(time*0.1)*4.0);

    //p.y = mod(p.y+0.5, 1.0) - 0.5; 
    return length(p*vec3(0.0,1.0,1.0)) - 0.5 + 0.05*sin(time+p.x*4.0)+0.03*sin(time*1.1+p.x*17.0)+0.04*sin(time*1.21+p.x*42.0); 
}
vec3 get_normal(in vec3 p)
{
    vec3 eps = vec3(0.001, 0, 0); 
    float nx = scene(p + eps.xyy) - scene(p - eps.xyy); 
    float ny = scene(p + eps.yxy) - scene(p - eps.yxy); 
    float nz = scene(p + eps.yyx) - scene(p - eps.yyx); 
    return normalize(vec3(nx,ny,nz)); 
}

// ambient occlusion approximation
// multiply with color
float ambientOcclusion(vec3 p, vec3 n)
{
    const int steps = 3;
    const float delta = 0.5;

    float a = 0.0;
    float weight = 1.0;
    for(int i=1; i<=steps; i++) {
        float d = (float(i) / float(steps)) * delta; 
        a += weight*(d - scene(p + n*d));
        weight *= 0.5;
    }
    return clamp(1.0 - a, 0.0, 1.0);
}

float random(vec3 scale, float seed) { 
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed); 
} 

vec3 cosineWeightedDirection(float seed, vec3 normal) {
    float u = random(vec3(12.9898, 78.233, 151.7182), seed); 
    float v = random(vec3(63.7264, 10.873, 623.6736), seed); 
    float r = sqrt(u); 
    float angle = 6.283185307179586 * v; 
    vec3 sdir, tdir; 
    if (abs(normal.x)<.5) { 
        sdir = cross(normal, vec3(1,0,0)); 
    } else { 
        sdir = cross(normal, vec3(0,1,0)); 
    } 
    tdir = cross(normal, sdir); 
    return r*cos(angle)*sdir + r*sin(angle)*tdir + sqrt(1.-u)*normal; 
} 

vec3 uniformlyRandomDirection(float seed) { 
    float u = random(vec3(12.9898, 78.233, 151.7182), seed); 
    float v = random(vec3(63.7264, 10.873, 623.6736), seed); 
    float z = 1.0 - 2.0 * u; float r = sqrt(1.0 - z * z); 
    float angle = 6.283185307179586 * v; 
    return vec3(r * cos(angle), r * sin(angle), z); 
} 

vec3 uniformlyRandomVector(float seed) { 
    return uniformlyRandomDirection(seed) * sqrt(random(vec3(36.7539, 50.3658, 306.2759), seed)); 
} 

void main( void ) {

    vec2 p = 2.0*( gl_FragCoord.xy / resolution.xy )-1.0;
    p.x *= resolution.x/resolution.y; 

    
    vec3 campos = vec3(sin(time)*10.0,1,0); 
    vec3 camtar = vec3(0,1,1); 
    vec3 camup = vec3(0,1,0);
    
    vec3 camdir = normalize(camtar-campos);
    vec3 cu = normalize(cross(camdir, camup)); 
    vec3 cv = normalize(cross(cu, camdir)); 
    
    vec3 color = 0.2*vec3(1,1,1)*clamp(1.0-0.5*length(p),0.0,1.0); 
    
    vec3 ro = vec3(0,0,2.0);
    vec3 rd = normalize(vec3(p.x,p.y,-1.0)); 
    //vec3 ro = campos; 
    //vec3 rd = normalize(p.x*cu + p.y*cv + camdir); 
    
    //ro = rotatey(ro, time); 
    //rd = rotatey(rd, time); 
    
    vec3 pos = ro; 
    float dist = 0.0; 
    float d; 
    for (int i = 0; i < 96; i++) {
        d = scene(pos)*0.5; 
        pos += rd*d;
        dist += d; 
    }
    if (dist < 100.0 && abs(d) < 0.0001) {
        vec3 n = get_normal(pos); 
        vec3 l = normalize(vec3(1,1,1)); 
        vec3 r = reflect(rd, n); 
        float shade = ambientOcclusion(pos+0.01*n, n); 
        float fres = clamp(dot(n,-rd),0.0, 1.0); 
        float spec = pow(clamp(dot(r,normalize(vec3(0,1,0))), 0.0, 1.0), 5.0); 
        float spec1 = pow(clamp(dot(r,normalize(vec3(-1,0,0))), 0.0, 1.0), 4.0)*fres; 
        float spec2 = pow(clamp(dot(r,normalize(vec3(1,0,-1.0))), 0.0, 1.0), 23.0); 
        float spec3 = pow(clamp(dot(r,normalize(vec3(5,0,0.5))), 0.0, 1.0), 2.0)*fres; 
        //float diff = clamp(dot(n,l), 0.0, 1.0); 
        color = 0.1*mix(vec3(1,1,1)*0.8,vec3(1,1,1)*0.5,fres); 
        color += 0.05*vec3(1,1,1)*clamp(-n.y,0.0,1.0); 
        color += vec3(1,1,1)*spec; 
        color += 0.2*vec3(1,1,1)*spec1; 
        //color += 0.1*vec3(1,1,1)*pow(spec1,16.0); 
        color += 0.2*vec3(1,1,1)*spec2; 
        color += 0.1*vec3(1,1,1)*spec3; 
        //color += 0.1*vec3(1,1,1)*pow(spec3,1.0); 
        color *= shade; 
    }
        
    vec3 rc = uniformlyRandomVector(1232.2+time); 
    color += 0.005*rc;
                  
    
    glFragColor = vec4(color, 1.0); 
}
