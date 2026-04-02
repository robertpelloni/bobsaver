#version 420

// original https://www.shadertoy.com/view/WtdyDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define hue(v) ( .6 + .6 * cos( 6.3*(v) + vec4(0,23,21,0) ) )
#define hash21(p) fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453)
#define hash33(p) fract(sin( (p) * mat3( 127.1,311.7,74.7 , 269.5,183.3,246.1 , 113.5,271.9,124.6) ) *43758.5453123)

bool insideTriangle(vec2 a, vec2 b, vec2 c, vec2 p) {
    vec2 q = inverse(mat2(b-a, c-a))*(p-a);
    return q.x >= 0. && q.y >= 0. && q.x+q.y <= 1.;
}

vec3 colorize (vec3 r) {
    int c = int(r.z*5.);
    if (c == 0) return vec3(38, 70, 83)/255.;
    if (c == 1) return vec3(42, 157, 143)/255.;
    if (c == 2) return vec3(233, 196, 106)/255.;
    if (c == 3) return vec3(244, 162, 97)/255.;
    /* c == 4*/ return vec3(231, 111, 81)/255.;
}

vec4 render(vec2 U) {

    vec2 R = resolution.xy, pw=1./R, uv=U*pw, z=1.04*(2.0*U-R)/R.y;
    
    vec2 a = vec2(2./sqrt(3.), -1.), b = vec2(0,1), c = vec2(-2./sqrt(3.), -1.);
    vec2 tmp;
#define SWAP(_v, _w) {tmp=_v; _v=_w; _w=tmp;}

    if (!insideTriangle(a,b,c,z)) {
        return vec4(0);
    }
    
    float t = fract(time/40.);
    float iterations = .3+14.*(.5-abs(t-.5));
    float fill = 1.;
    vec3 rand = hash33(vec3(float(fill), 0, 0));
    vec3 prevRand;
    vec4 oldColor, newColor;
    for (int i = 0; i < 10; i++) {
        if (float(i) >= floor(iterations)+1.) continue;
        if (i == 0) {
            oldColor = vec4(0);
            newColor = vec4(colorize(rand), 1.);
        } else {
            oldColor = newColor;
            if (rand.x > .66) {
                SWAP(a, c);
            } else if(rand.x > .33){ 
                SWAP(a,b);
            }
            float div = .25+.5*rand.y+.1*sin(time);
            vec2 n = mix(b, c, div);
            fill *= 2.;
            if (insideTriangle(a,b,n,z)) {
                c = n; fill+=1.;
            } else {
                b = n;
            }
            prevRand = rand;
            rand = hash33(vec3(float(fill), 0, 0));
            newColor = vec4(colorize(rand), 1.0);
        }
    }
    
    vec2 center = (a+b+c)/3.;
    float maxDist = max(
        distance(a,center),
        max(distance(b,center), distance(c,center)));
    float f = distance(z, center) / maxDist;
    float transition = clamp(0.,1.,.5+3.*(fract(iterations)-.5));
    if (f < transition) {
        return newColor;
    } else {
        return oldColor;
    }
}
void main(void) { //WARNING - variables void ( out vec4 O, in vec2 U ) { need changing to glFragColor and gl_FragCoord.xy
    vec2 d = vec2(.5,0);
    glFragColor = (
        render(gl_FragCoord.xy+d.xy)+
        render(gl_FragCoord.xy-d.xy)+
        render(gl_FragCoord.xy+d.yx)+
        render(gl_FragCoord.xy-d.yx)
    )*.25;
}
