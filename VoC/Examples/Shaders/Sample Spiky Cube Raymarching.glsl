#version 420

// original https://www.shadertoy.com/view/Wsjfzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592

#define MAX_ITER 300
#define MAX_DIST 10000.0

#define SET_CLOSER(dst,src) if (src.distance < dst.distance) dst = src

#define X vec3(1, 0, 0)
#define Y vec3(0, 1, 0)
#define Z vec3(0, 0, 1)

vec3 SPIKE_COLOR; //Controlled on mouse click

//Spike count per side (sweeps over time)
float CYCLES;

// Smooth HSV to RGB conversion (from https://www.shadertoy.com/view/MsS3Wc)
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    

    return c.z * mix( vec3(1.0), rgb, c.y);
}

mat3 rotationX(float angle) {
    vec3 u = vec3(1, 0, 0);
    vec3 v = vec3(0, cos(angle), -sin(angle));
    vec3 w = vec3(0, sin(angle), cos(angle));
    return mat3(u, v, w);
}

mat3 rotationY(float angle) {
    vec3 u = vec3(cos(angle), 0, sin(angle));
    vec3 v = vec3(0, 1, 0);
    vec3 w = vec3(-sin(angle), 0, cos(angle));
    return mat3(u, v, w);
}

mat3 rotationZ(float angle) {
    vec3 u = vec3(cos(angle), -sin(angle), 0);
    vec3 v = vec3(sin(angle), cos(angle), 0);
    vec3 w = vec3(0, 0, 1);
    return mat3(u, v, w);
}

mat3 rotationMatrix(vec3 angles) {
    return rotationZ(angles.z) * rotationY(angles.y) * rotationX(angles.x);
}

struct DistanceObject {
    float distance;
    vec3 color;
    int objectId;
};
struct HitData {
    vec3 color;
    float distance;
    int iterations;
    vec3 position;
    vec3 normal;
    float incidence;
};

float sdSphere(vec3 pos, float rad) {
    return length(pos) - rad;
}

float sdPlane(vec3 pos) {
    return pos.y;
}

vec3 boxNormal(vec3 pos, vec3 b) {
    float epsilon = 1e-3;
    
    vec3 abdD = min(abs(pos) / b, 1.) / 2.;
    vec3 d = clamp(pos / b, -1., 1.)*.5;
    
    vec2 uv;
    
    vec3 u, v;
    bool reverse = false;
    
    if (abdD.x > 0.5 - epsilon){
        uv = d.yz;
        if (d.x < 0.) {
            reverse = true;
        }
        u = Y;
        v = Z;
    }
    else if (abdD.y > 0.5 - epsilon){
        uv = d.zx;
        if (d.y < 0.) {
            reverse = true;
        }
        u = Z;
        v = X;
    }
    else if (abdD.z > 0.5 - epsilon){
        uv = d.xy;
        if (d.z < 0.) {
            reverse = true;
        }
        u = X;
        v = Y;
    }
    
    if (reverse)
        uv = -uv;
    
    //Spike height function
    vec2 k = abs(cos(uv * PI * CYCLES)) * cos(uv * PI);
    
    float c = CYCLES;
    vec2 x = uv;
    //Derivative of spike height function
    vec2 dH = -PI*abs(cos(c*PI*x))*sin(PI*x)-(c*PI*sin(2.*c*PI*x)*cos(PI*x))/(2.*abs(cos(c*PI*x)));
    dH *= k.yx;
    vec2 angles = atan(dH);
    //angles = vec2(0., 0.);
    
    vec3 right = rotationMatrix(angles.x*v) * u;
    vec3 top = rotationMatrix(-angles.y*u) * v;
    
    vec3 norm;
    norm = normalize(cross(right, top));
    if (reverse)
        norm = -normalize(cross(right, top));
    
    return norm;
}

DistanceObject sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    vec3 abdD = min(abs(p) / b, 1.) / 2.;
    vec3 d = clamp(p / b, -1., 1.)*.5;
    
    float dist = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
    
    float height;
    
    // In range: (-1, 1)
    vec2 uv;
    
    if (abdD.x > 0.499)
        uv = d.yz;
    else if (abdD.y > 0.499)
        uv = d.xz;
    else if (abdD.z > 0.499)
        uv = d.xy;
    
    //Spike height function
    vec2 val = abs(cos(uv * PI * CYCLES)) * cos(uv * PI);
    
    height = val.x * val.y * 0.3 * length(b);
    //height = 0.;

    dist -= height;
    
    //vec3 col = boxNormal(p, b);
    //vec3 col = vec3(val.x * val.y*2., 0, 0);
    float value = val.x * val.y * 2.;
    vec3 col = SPIKE_COLOR * value;
    //col = vec3(1.);
    //return DistanceObject(dist, vec3(height*5., 0, 0), 5);
    //return DistanceObject(dist, norm, 5);
    return DistanceObject(dist, col, 5);
}

DistanceObject map(vec3 pos, vec3 rayDir) {
    
    DistanceObject nearest = DistanceObject(MAX_DIST, vec3(1, 0, .5), -1);
    
    
    //  WRITE OBJECTS HERE
    //SET_CLOSER(nearest, DistanceObject(sdSphere(pos - vec3(4, 0, 0), 1.), vec3(1), 3));
    
    pos = mod(pos + 2., 4.) - 2.;
    
    //if (length(pos) < 5.) {
        DistanceObject box = sdBox(pos, vec3(1, 1, 1));
        SET_CLOSER(nearest, box);
    //}
    
    //SET_CLOSER(nearest, DistanceObject(sdPlane(pos + vec3(0, 10, 0)), vec3(0, 1, 0), 2));
    
    
    return nearest;
}

vec3 calculateNormal(int objectId, vec3 position) {
    switch (objectId) {
        case 2: //plane
            return vec3(0, 1, 0);
        case 3: //sphere
            return normalize(position - vec3(4, 0, 0));
        case 5: //cube
            position = mod(position + 2., 4.) - 2.;
            return boxNormal(position, vec3(1, 1, 1));
        default:
            return vec3(1, 0, 0);
    }
}

HitData render(vec3 pos, vec3 rayDir) {
    DistanceObject obj;
    int i;
    float dist = 0.;
    for (i = 0; i < MAX_ITER; i++) {
        obj = map(pos, rayDir);
        
        obj.distance *= 0.3;
        
        dist += obj.distance;
        pos += rayDir * obj.distance;
        
        if (obj.distance < .0001) {
            break;
        }
    }
    
    if (i == MAX_ITER) {
        dist = MAX_DIST;
        obj.color = vec3(0.);
    }
    
    vec3 normal = calculateNormal(obj.objectId, pos);
    //normal = rotationMatrix(vec3(PI/2.,0,0)) * -rayDir;
    
    float incidence = dot(-normal, rayDir) / (length(normal)*length(rayDir));
    
    //incidence *= 1000000.0;
    //incidence = min(incidence, 1.);
    /*
    if (obj.objectId == 5)
        incidence=1.;
    */
    HitData res = HitData(obj.color, dist, i, pos, normal, incidence);
    
    return res;
}

void main(void)
{
    CYCLES = (sin(time) * 0.5 + 0.5) * 7.0 + 1.0;
    
    SPIKE_COLOR = hsv2rgb_smooth(vec3(1.,1.,1.));//vec3(mouse.x*resolution.xy.x / resolution.x, 1., 1.));
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.y;
    // Normalized pixel coordinates (from -1 to 1)
    vec2 coord = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec2 cameraAngle = vec2((sin(time)*0.3+0.8)*-PI/2.0*0.5, time);
    //cameraAngle.x = -mouse*resolution.xy.y / 100.0 + (PI / 2.);
    //cameraAngle.y = mouse*resolution.xy.x / 100.0;
    mat3 cameraMatrix = rotationMatrix(vec3(cameraAngle, 0));
    
    vec3 cameraPosition = cameraMatrix * -vec3(0, 0, 1) * 4.0;
    
    
    vec3 direction = cameraMatrix * vec3(coord.x, coord.y, (sin(time*3.)*.5+.5)*2.+1.0);
    direction = normalize(direction);

    vec3 col;
    
    HitData data = render(cameraPosition, direction);
    
    col = data.color;
    //col *= inversesqrt(data.distance);
    //col *= float(data.iterations) / 10.0;
    //col *= calculateIncidence(cameraPosition, direction);
       col *= data.incidence;
    col = mix(col, vec3(0.1), clamp(sqrt(data.distance / 100.0), 0., 1.));
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
