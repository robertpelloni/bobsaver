#version 420

// original https://neort.io/art/bv69k6s3p9f7gigedmng

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define rand(z) fract(sin(z)*1352.2342)

const float pi2 = acos(-1.)*2.;

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 rand2f(vec2 co) {
    vec2 z = vec2(dot(co, vec2(1.1521, 1.4322)), dot(co, vec2(1.2341, 1.3251)));
    return rand(z);
}

// Reference:
// https://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm
float voronoiBorder(vec2 x, float seed, float phase) {
    vec2 xi = floor(x);
    vec2 xf = fract(x);
    
    vec2 res = vec2(10.);
    for(int i=-1; i<=1; i++) {
        for(int j=-1; j<=1; j++) {
            vec2 b = vec2(i,j);
            vec2 rv = rand2f(xi+b+seed*1.3412);
            rv = sin(rv*pi2 + phase)*.5+.5;
            rv *= .75;
            vec2 r = b+rv - xf;
            float d = dot(r,r);
            
            if(d<res.x) {
                res.y = res.x;
                res.x = d;
            } else if(d<res.y) {
                res.y = d;
            }
        }
    }
    res = sqrt(res);
    return 1.-smoothstep(-.1, .1, res.y-res.x);
}

float smoothFloor(float x, float s) {
    return floor(x-.5)+smoothstep(.5-s, .5+s, fract(x-.5));
}

void main( void ) {
    vec2 p = (gl_FragCoord.xy*2.-resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0);
    
    p *= rotate(time*.2);
    float cPos = time;
    float id = ceil(cPos);
    
    for(float i=0.; i<20.; i++) {
        float L = 1.-fract(cPos)+i;
        float a = atan(.3, L)*5.;
        float r = rand(id)*pi2;
        float phase = time + r;
        phase = smoothFloor(phase, .2);
        vec2 rv = rand2f(vec2(id, id*1.31223)) * 10.;
        
        // Reference:
        // https://www.shadertoy.com/view/4sl3Dr
        float v1 = voronoiBorder(p/a+rv, id, phase);
        float v2 = voronoiBorder(p/a*.5+time*vec2(cos(r),sin(r)), id, phase);
        float v = pow(v1*v2, 3.) * 200.;
        
        color += v1*vec3(.9, .4, 0.);
        color += v;
        id++;
    }
    //color += atan(p.y, p.x)*tan(time);
    glFragColor = vec4(color, 1.);
}
