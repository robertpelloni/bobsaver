#version 420

// original https://www.shadertoy.com/view/3tscD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
float GRatio = 1.618033988;

int maxStep = 255;
float minDist = 0.0;
float maxDist = 200.0;
float e = 0.0001;

struct Camera{
    vec3 pos;
    vec3 look;
    vec3 up;
    vec3 right;
    float fov;
};

struct Sphere{
    vec3 pos;
    float r;
};

vec3 rotateX(vec3 p, float ang) {
  mat3 rmat = mat3(
    1., 0., 0.,
    0., cos(ang), -sin(ang),
    0., sin(ang), cos(ang));
  return rmat * p;
}
vec3 rotateY(vec3 p, float ang) {
  mat3 rmat = mat3(
    cos(ang), 0., sin(ang),
    0., 1., 0.,
    -sin(ang), 0., cos(ang));
  return rmat * p;
}
vec3 rotateZ(vec3 p, float ang) {
  mat3 rmat = mat3(
    cos(ang), -sin(ang), 0.,
    sin(ang), cos(ang), 0.,
    0., 0., 1.);
  return rmat * p;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

Camera getCamera(vec3 pos, vec3 look, vec3 up, float fov){
    Camera c;
    c.pos = pos;
    c.look = normalize(look - pos);
    c.right = normalize(cross(up, c.look));
    c.up = cross(c.look, c.right);
    c.fov = fov;
    return c;
}

vec3 getRay(Camera c, vec2 coord){
    vec3 ray;
    
    vec2 nc = coord/resolution.xy;
    nc -= 0.5;
    nc.x *= resolution.x/resolution.y;
    
    ray += nc.x * c.right;
    ray += nc.y * c.up;
    ray += c.fov * c.look;
    
    return normalize(ray);
}

float sphereSdf(Sphere s, vec3 p){
    p -= s.pos;
    return length(p) - s.r;
}

float sdf(vec3 p){
    Sphere s = Sphere(vec3(0.0,0.0,0.0), 0.6);
    Sphere s2 = Sphere(vec3(0.1,0.1 + sin(time),0.0), 0.3);
    Sphere s3 = Sphere(vec3(0.2,0.1 + cos(time ) * 1.3,0.0), 0.4);
    
    
    float d;
    
    d = sphereSdf(s,p);
    d = smin(d, sphereSdf(s2,p), 0.3);
    d = smin(d, sphereSdf(s3,p), 0.3);
    
    return d;
}

void main(void) {
    Camera cam = getCamera(rotateY(vec3(1.0,0.7, -1.0),time * 0.1), vec3(0.0,0.0,0.0), vec3(0.0,1.0,0.0), 0.3);
    
    
    vec3 ray = getRay(cam, gl_FragCoord.xy);
    
    float d1 = 0.0;
    float d2 = 0.0;
    
    float h;
    
    vec3 n;
    
    for(int i=0; i < maxStep; i++){
        d1 = sdf(d2*ray + cam.pos);
        if(d1 < e)
            break;
        d2 += d1;
        if(d2 > maxDist)
            break;
        h++;
    }
    
    d2 = min(d2, maxDist);
    
    vec3 p = d2 * ray + cam.pos; 
    
    n = normalize(vec3(
        sdf(vec3(p.x + e, p.y, p.z)) - sdf(vec3(p.x - e, p.y, p.z)),
        sdf(vec3(p.x, p.y + e, p.z)) - sdf(vec3(p.x, p.y - e, p.z)),
        sdf(vec3(p.x, p.y, p.z  + e)) - sdf(vec3(p.x, p.y, p.z - e))
    ));
    
    float c = dot(n, rotateY(normalize(vec3(5.0,3.0, 5.0)), time * 0.3));
    
    if(d2 >= maxDist){
        float spot;
        
        vec3 spvec = vec3(0.0,0.0,1.0);
        
        float spn = 30.0;
        
        for(float i=0.0; i<spn; i++){
            for(float j=0.0; j<spn; j++){
                spot = max(spot,dot(ray, spvec));
                spvec = rotateZ(spvec, PI * 2.0 / spn);
            }
            spvec = rotateY(spvec, PI * 1.0 / spn);
        }
        if(spot < 0.9999)
            glFragColor = vec4(0.949, 0.0941, 0.28235, 1.0);
        else
            glFragColor = vec4(1.0);
    }
    else{
        float spot;
        n = rotateX(n, time * 0.3);
        n = rotateY(n, time * 0.3);
        /*spot = max(spot, dot(n ,normalize( vec3(-1,  GRatio,  0) )));
        spot = max(spot, dot(n ,normalize( vec3( 1,  GRatio,  0) )));
        spot = max(spot, dot(n ,normalize( vec3(-1, -GRatio,  0) )));
        spot = max(spot, dot(n ,normalize( vec3( 1, -GRatio,  0) )));
        spot = max(spot, dot(n ,normalize( vec3( 0, -1,  GRatio) )));
        spot = max(spot, dot(n ,normalize( vec3( 0,  1,  GRatio) )));
        spot = max(spot, dot(n ,normalize( vec3( 0, -1, -GRatio) )));
        spot = max(spot, dot(n ,normalize( vec3( 0,  1, -GRatio) )));
        spot = max(spot, dot(n ,normalize( vec3( GRatio,  0, -1) )));
        spot = max(spot, dot(n ,normalize( vec3( GRatio,  0,  1) )));
        spot = max(spot, dot(n ,normalize( vec3(-GRatio,  0, -1) )));
        spot = max(spot, dot(n ,normalize( vec3(-GRatio,  0,  1) )));*/
        // LOL
spot = max(spot, dot(n ,normalize(vec3(-0.52573, 0.85065, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(0.52573, 0.85065, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(-0.52573, -0.85065, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(0.52573, -0.85065, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, -0.52573, 0.85065))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, 0.52573, 0.85065))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, -0.52573, -0.85065))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, 0.52573, -0.85065))));
spot = max(spot, dot(n ,normalize(vec3(0.85065, 0.00000, -0.52573))));
spot = max(spot, dot(n ,normalize(vec3(0.85065, 0.00000, 0.52573))));
spot = max(spot, dot(n ,normalize(vec3(-0.85065, 0.00000, -0.52573))));
spot = max(spot, dot(n ,normalize(vec3(-0.85065, 0.00000, 0.52573))));
spot = max(spot, dot(n ,normalize(vec3(-0.80902, 0.50000, 0.30902))));
spot = max(spot, dot(n ,normalize(vec3(-0.50000, 0.30902, 0.80902))));
spot = max(spot, dot(n ,normalize(vec3(-0.30902, 0.80902, 0.50000))));
spot = max(spot, dot(n ,normalize(vec3(0.30123, 0.80413, 0.51248))));
spot = max(spot, dot(n ,normalize(vec3(-0.01550, 0.99988, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(-0.00000, 1.00000, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(0.31673, 0.81371, -0.48740))));
spot = max(spot, dot(n ,normalize(vec3(-0.31673, 0.81371, -0.48740))));
spot = max(spot, dot(n ,normalize(vec3(-0.30902, 0.80902, -0.50000))));
spot = max(spot, dot(n ,normalize(vec3(-0.48740, 0.31673, -0.81371))));
spot = max(spot, dot(n ,normalize(vec3(-0.80413, 0.51248, -0.30123))));
spot = max(spot, dot(n ,normalize(vec3(-0.80902, 0.50000, -0.30902))));
spot = max(spot, dot(n ,normalize(vec3(-1.00000, 0.00000, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(0.30902, 0.80902, 0.50000))));
spot = max(spot, dot(n ,normalize(vec3(0.48740, 0.31673, 0.81371))));
spot = max(spot, dot(n ,normalize(vec3(0.80413, 0.51248, 0.30123))));
spot = max(spot, dot(n ,normalize(vec3(-0.51248, -0.30123, 0.80413))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, 0.01550, 0.99988))));
spot = max(spot, dot(n ,normalize(vec3(-0.81371, -0.48740, -0.31673))));
spot = max(spot, dot(n ,normalize(vec3(-0.81371, -0.48740, 0.31673))));
spot = max(spot, dot(n ,normalize(vec3(-0.50000, 0.30902, -0.80902))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, 0.01550, -0.99988))));
spot = max(spot, dot(n ,normalize(vec3(-0.51248, -0.30123, -0.80413))));
spot = max(spot, dot(n ,normalize(vec3(0.30902, 0.80902, -0.50000))));
spot = max(spot, dot(n ,normalize(vec3(0.80413, 0.51248, -0.30123))));
spot = max(spot, dot(n ,normalize(vec3(0.48740, 0.31673, -0.81371))));
spot = max(spot, dot(n ,normalize(vec3(0.81371, -0.48740, 0.31673))));
spot = max(spot, dot(n ,normalize(vec3(0.50000, -0.30902, 0.80902))));
spot = max(spot, dot(n ,normalize(vec3(0.30123, -0.80413, 0.51248))));
spot = max(spot, dot(n ,normalize(vec3(0.30902, -0.80902, 0.50000))));
spot = max(spot, dot(n ,normalize(vec3(-0.30902, -0.80902, 0.50000))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, -1.00000, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(-0.30902, -0.80902, -0.50000))));
spot = max(spot, dot(n ,normalize(vec3(0.30902, -0.80902, -0.50000))));
spot = max(spot, dot(n ,normalize(vec3(0.50000, -0.30902, -0.80902))));
spot = max(spot, dot(n ,normalize(vec3(0.80902, -0.50000, -0.30902))));
spot = max(spot, dot(n ,normalize(vec3(1.00000, 0.00000, 0.00000))));
spot = max(spot, dot(n ,normalize(vec3(0.80902, -0.50000, 0.30902))));
spot = max(spot, dot(n ,normalize(vec3(0.50000, 0.30902, 0.80902))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, 0.00000, 1.00000))));
spot = max(spot, dot(n ,normalize(vec3(-0.50000, -0.30902, 0.80902))));
spot = max(spot, dot(n ,normalize(vec3(-0.80902, -0.50000, 0.30902))));
spot = max(spot, dot(n ,normalize(vec3(-0.80902, -0.50000, -0.30902))));
spot = max(spot, dot(n ,normalize(vec3(-0.50000, -0.30902, -0.80902))));
spot = max(spot, dot(n ,normalize(vec3(0.00000, 0.00000, -1.00000))));
spot = max(spot, dot(n ,normalize(vec3(0.50000, 0.30902, -0.80902))));
spot = max(spot, dot(n ,normalize(vec3(0.80902, 0.50000, -0.30902))));
spot = max(spot, dot(n ,normalize(vec3(0.80902, 0.50000, 0.30902))));
        if(spot < 0.98)
            glFragColor = vec4(0.949, 0.0941, 0.28235, 1.0);
        else
            glFragColor = vec4(1.0);
    }
}
