#version 420

// original https://www.shadertoy.com/view/flXyz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.1415926535

// Tranformations between polar and cartesian coordinates
void toPolar(inout vec2 p) {
    float r = length(p);
    p.y = atan(p.y, p.x);
    p.x = r;
}

void toCartesian(inout vec2 p) {
    float c = cos(p.y);
    float s = sin(p.y);
    p.y = p.x * s;
    p.x = p.x * c;
}

// Creates rotation matrix
mat2x2 makeRotMatrix(float rad) {
    float c = cos(rad), s = sin(rad);
    return mat2x2(c, -s, s, c);
}

// Folds
void planeFold(inout vec3 p, vec2 n, float d) {
    p.xy -= 2.0 * min(0.0, dot(p.xy, n) - d) * n;
}

void nGonFold(inout vec3 p, int n) {
    vec2 p_t = p.xy;
    toPolar(p_t);
    float theta = 2.*pi / float(n);
    p_t.y = mod(p_t.y + theta/2., theta) - theta/2.;
    toCartesian(p_t);
    p.xy = p_t;
}

// Scale, Translation, Rotation
void scaleTranslate(inout vec3 p, vec2 t, float s) {
    p.xy -= t;
    p /= s;
    p.z = abs(p.z);
    
}

void rot(inout vec3 p, mat2x2 r) {
    p.xy =  r * p.xy;
}

// Distance functions
float de_circle(vec3 p, float r) {
    return (length(p.xy) - r) / p.z;
}

// Fractal
float rolling(inout vec3 p, int num_it, float speed1, float speed2) {
    mat2x2 r1 = makeRotMatrix(time * speed1);
    mat2x2 r2 = makeRotMatrix(-time * speed2);
    
    float s = 0.29;
    float reflect_d = 0.33333;
    
    int i;
    rot(p, r2);
    for(i = 0; i < num_it; i++)
    {   
        nGonFold(p, 7);
        planeFold(p, vec2(1., 0.), reflect_d);
        scaleTranslate(p, vec2(2./3., 0.), s);
        rot(p, r1);
    }
    
    float d = de_circle(p, 1.);
    return d;
}

// Main
void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.) / (min(resolution.x, resolution.y) / 2.);
    float min_zoom = 0.005;
    float max_zoom = 1.;
    float t = (0.5 + 0.5*cos(time * 0.3));
    float zoom = 1.;
    //zoom = min_zoom + (max_zoom - min_zoom) * t);    // linear interpolation
    zoom = pow(min_zoom, 1. - t) * pow(max_zoom, t); // log interpolation
    
    uv *= zoom;   
    vec3 p = vec3(uv, 1.0);
    
    float d = rolling(p, 20, -1./3., 1./5.);
    
    vec3 col = vec3(1.0);
    col *= smoothstep(0.001 * zoom, 0.0009 * zoom, d); 

    // Output to screen
    glFragColor = vec4(col,1.0);
}
