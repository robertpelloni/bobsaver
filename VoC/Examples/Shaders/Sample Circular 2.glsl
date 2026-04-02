#version 420

// original https://www.shadertoy.com/view/stfSWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPSILON (0.001)
#define MAX_DEPTH (1000.0)
#define MIN_DEPTH (EPSILON * 2.0)
#define RINGS (20)
#define PI (3.14159265359)
#define TAU (PI * 2.0)
#define LINE_THICKNESS (0.012)

vec3 rgb2lab(vec3 c);
vec3 lab2rgb(vec3 c);

// https://gist.github.com/onedayitwillmake/3288507
mat4 rotationX( in float angle ) {
    return mat4(    1.0,        0,            0,            0,
                     0,     cos(angle),    -sin(angle),        0,
                    0,     sin(angle),     cos(angle),        0,
                    0,             0,              0,         1);
}

mat4 rotationY( in float angle ) {
    return mat4(    cos(angle),        0,        sin(angle),    0,
                             0,        1.0,             0,    0,
                    -sin(angle),    0,        cos(angle),    0,
                            0,         0,                0,    1);
}

mat4 rotationZ( in float angle ) {
    return mat4(    cos(angle),        -sin(angle),    0,    0,
                     sin(angle),        cos(angle),        0,    0,
                            0,                0,        1,    0,
                            0,                0,        0,    1);
}

vec3 pointMultiply(vec3 point, mat4 matrix) {
    return (matrix * vec4(point, 0.0)).xyz;
}

float sphereSDF(vec3 point) {
    return length(point) - 0.2;
}

float arcSDF(vec3 point, float radius, float angle1, float angle2) {
    point = pointMultiply(point, rotationX(radians(30.0)));
    float sizeD = LINE_THICKNESS;
    float angle = mod(atan(point.z, point.x), TAU);
    if(angle1 > angle2) angle2 += TAU;
    if(angle1 > angle) angle += TAU;
    if(angle >= angle1 && angle <= angle2) {
        return min(
            length(vec3(cos(angle1), 0.0, sin(angle1)) * radius - point) - sizeD,
            length(vec3(cos(angle2), 0.0, sin(angle2)) * radius - point) - sizeD
        );
    }
    float r = radius;
    return length(normalize(vec3(point.x, 0.0, point.z)) * r - point) - sizeD;
}

float sceneSDF(vec3 point) {
    float dist = MAX_DEPTH;
    
    for(int i = 0; i < RINGS; i++) {
        float angle1 = fract(time * 1.0 - float(i) / float(RINGS) * 2.0) * TAU;
        float angle2 = mod(angle1 + PI * 0.75, TAU);
        dist = min(dist, arcSDF(point, 1.0 + float(i) / 10.0, angle1, angle2));
    }
    
    point = pointMultiply(point, rotationX(radians(30.0)));
    point = pointMultiply(point, rotationY(-TAU * time / 32.0));
    point = (fract(point * 0.05) / 0.05) - 10.0;
    dist = min(dist, sphereSDF(point));
    
    return dist;
}

#define C1 (rgb2lab(vec3(0.3, 0.7, 0.8)))
#define C2 (rgb2lab(vec3(0.9, 0.2, 0.4)))
#define C3 (rgb2lab(vec3(0.3, 0.5, 0.6)))
vec3 colorField(vec3 point) {
    float lerp = length(pointMultiply(point, rotationX(radians(30.0))).xz);
    lerp = (lerp - 1.0) / (float(RINGS - 1) / 10.0);
    lerp = max(0.0, lerp);
    if(lerp > 1.1) return lab2rgb(C3);
    lerp = pow(lerp, 1.0);
    return lab2rgb(C1 * (1.0 - lerp) + C2 * lerp);
}

float march(vec3 from, vec3 dir) {
    float depth = MIN_DEPTH;
    for(int i = 0; i < 256; i++) {
        float nearest = sceneSDF(from + dir * depth);
        if(nearest < EPSILON) return depth;
        depth += nearest;
        if(depth > MAX_DEPTH) return MAX_DEPTH;
    }
    return depth;
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

void main(void)
{
    vec3 pos = vec3(0.0, -0.35, 10.0);
    vec3 dir = rayDirection(45.0, resolution.xy);
    float depth = march(pos, dir);
    float upness = smoothstep(-0.3, 0.3, dot(dir, vec3(0.0, 1.0, 0.0)));
    vec3 background = vec3(0.1, 0.0, 0.2);
    if(depth > MAX_DEPTH - EPSILON) {
        glFragColor = vec4(pow(background, vec3(2.2)), 1.0);
        return;
    }
    vec3 hitPos = pos + dir * depth;
    //vec3 lightPos = vec3(cos(time * 6.28 / 2.0) * 4.5, sin(time * 6.28 / 2.0) * 4.5, 1.0);
    //vec3 color = background * 0.5;
    //color += vec3(0.98, 0.1, 0.4);
    vec3 color = colorField(hitPos);
    glFragColor = vec4(pow(color, vec3(2.2)), 1.0);
}

//CIE L*a*b* (CIELAB, L* for lightness, a* from green to red, b* from blue to yellow)
//Source: https://gist.github.com/mattatz/44f081cac87e2f7c8980 (HLSL)
vec3 rgb2xyz(vec3 c){
    vec3 tmp=vec3(
        (c.r>.04045)?pow((c.r+.055)/1.055,2.4):c.r/12.92,
        (c.g>.04045)?pow((c.g+.055)/1.055,2.4):c.g/12.92,
        (c.b>.04045)?pow((c.b+.055)/1.055,2.4):c.b/12.92
    );
    mat3 mat=mat3(
        .4124,.3576,.1805,
        .2126,.7152,.0722,
        .0193,.1192,.9505
    );
    return 100.*(tmp*mat);
}
vec3 xyz2lab(vec3 c){
    vec3 n=c/vec3(95.047,100.,108.883),
         v=vec3(
        (n.x>.008856)?pow(n.x,1./3.):(7.787*n.x)+(16./116.),
        (n.y>.008856)?pow(n.y,1./3.):(7.787*n.y)+(16./116.),
        (n.z>.008856)?pow(n.z,1./3.):(7.787*n.z)+(16./116.)
    );
    return vec3((116.*v.y)-16.,500.*(v.x-v.y),200.*(v.y-v.z));
}
vec3 rgb2lab(vec3 c){
    vec3 lab=xyz2lab(rgb2xyz(c));
    return vec3(lab.x/100.,.5+.5*(lab.y/127.),.5+.5*(lab.z/127.));
}
vec3 lab2xyz(vec3 c){
    float fy=(c.x+16.)/116.,
          fx=c.y/500.+fy,
          fz=fy-c.z/200.;
    return vec3(
         95.047*((fx>.206897)?fx*fx*fx:(fx-16./116.)/7.787),
        100.   *((fy>.206897)?fy*fy*fy:(fy-16./116.)/7.787),
        108.883*((fz>.206897)?fz*fz*fz:(fz-16./116.)/7.787)
    );
}
vec3 xyz2rgb(vec3 c){
    mat3 mat=mat3(
        3.2406,-1.5372,-.4986,
        -.9689, 1.8758, .0415,
         .0557, -.2040,1.0570
    );
    vec3 v=(c/100.0)*mat,
         r=vec3(
        (v.r>.0031308)?((1.055*pow(v.r,(1./2.4)))-.055):12.92*v.r,
        (v.g>.0031308)?((1.055*pow(v.g,(1./2.4)))-.055):12.92*v.g,
        (v.b>.0031308)?((1.055*pow(v.b,(1./2.4)))-.055):12.92*v.b
    );
    return r;
}
vec3 lab2rgb(vec3 c){return xyz2rgb(lab2xyz(vec3(100.*c.x,2.*127.*(c.y-.5),2.*127.*(c.z-.5))));}
