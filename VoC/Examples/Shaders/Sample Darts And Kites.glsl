#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/7sdXWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ANGLE_ONE 0.628319
#define ANGLE_TWO  1.88496
#define PI         3.14159
#define GOLDEN_RATIO 1.61803398875
#define N 11
#define scale (.02*(sin(time/3.)+2.))
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
    return -sqrt(d.x)*sign(d.y);
}

vec3 sdShape( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2, in vec3 shapeCol, in vec3 lineCol, in float thickness ) {
    vec3 col = lineCol;
    
    if(sdTriangle(p, p0, p1, p2) < 0.) col = shapeCol;
    
    if(min(sdSegment(p, p0, p1), sdSegment(p, p0, p2)) < thickness) col = lineCol;
    
    return col;
    
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;
    uv *= scale;
    uv += vec2(sin(time/10.), cos(time/10.)) *0.1;
    vec3 col = vec3(1);
   
    int v = clamp(int(5.0 * (atan(uv.x, uv.y) + PI) / PI), 0, 9);
    float offset = ANGLE_ONE /2. + float(v)/10. * PI * 2.;
    
    
    
    vec2 a = vec2(0.0, 0.0);
    vec2 b = a + vec2(sin(ANGLE_ONE / 2. + PI + offset), cos(ANGLE_ONE / 2. + PI + offset)) * 0.3;
    vec2 c = a + vec2(sin(PI - ANGLE_ONE / 2. + offset), cos(PI - ANGLE_ONE / 2. + offset)) * 0.3;
    
    if(v%2==0) {vec2 _ = b; b = c; c = _;}
    float d;
    bool blue = false;
    
    for(int i=0;i<N;i++) {
        if(blue)
        {
            vec2 q = b + (a - b) / GOLDEN_RATIO;
            vec2 r = b + (c - b) / GOLDEN_RATIO;
            if(sdTriangle(uv, r, c, a) < 0.) { b = c; c = a; a = r; }
            else if(sdTriangle(uv, r, q, a) < 0.) { blue = false; b = q; c = a; a = r; }
            else { c = b; b = r; a = q; }
        } else {
            vec2 p = a + (b - a) / GOLDEN_RATIO;
            if(sdTriangle(uv, c, p, b) < 0.) { a = c; c = b; b = p; }
            else { blue = true; b = c; c = a; a = p; }
        }
        
    }
    
    vec3 sCol = mix(vec3(0.859,0.263,0.263), vec3(0.306,0.306,0.792), float(blue));
    vec3 lCol = vec3(0.353,0.325,0.325);
    
    col = sdShape(uv, a, b, c, sCol, lCol, 0.0001);
    glFragColor = vec4(col, 1.);
}
