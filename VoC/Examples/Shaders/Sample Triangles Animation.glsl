#version 420

// original https://www.shadertoy.com/view/WdcBzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

vec2 line (vec2 a, vec2 b, vec2 p)
{
    vec2 pa = p-a, ba = b-a;
    float h = min(1., max(0., dot(pa, ba)/dot(ba, ba)));
    
    return vec2(length(pa - ba * h), h);
}

float ease(float x) {
    return mix(4. * x * x * x, 
               1. - pow(-2. * x + 2., 3.) / 2., step(0.5, x));
}
float ease2(float x) {
    return mix(pow(x/2., 0.5), 
               1. - pow(0.5 - x/2., 0.5), step(0.5, x));
}
float ease3(float x) {
    return mix(0.5 + pow((x - 0.5) * 2., 2.)/2., 
               0.5 - pow((x - 0.5) * 2., 2.)/2., step(0.5, x));
}

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

float leftSide(vec2 a, vec2 b, vec2 p) {    
     return 1. - step(0.0, (a.x - p.x) * (b.y - a.y) - (b.x - a.x) * (a.y - p.y));
}

float DrawLine(vec2 line, float prog) {
    float size = 0.002;
    line.x = smoothstep(size * 2., size, line.x);
    float prog1 = pow(prog, 0.8);
    float prog2 = pow(prog, 2.);

    return line.x;
    //return (smoothstep(1. - prog, 1. - prog, line.y) * line.x);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    uv *= 1.8;
    uv.y += 0.2;
    float time = time * 0.6 + 1000.;
    
    
    float sp = PI/1.5;
    float a = floor(time * 0.) * sp;
    vec2 cp1 = vec2(sin(a), cos(a));
    vec2 cp2 = vec2(sin(a + sp), cos(a + sp));
    vec2 cp3 = vec2(sin(a + sp * 2.), cos(a + sp * 2.));
    
    vec2 p1 = cp1;
    vec2 p2 = cp2;
    vec2 p3 = cp3;
    
    float pr = 0.;
    float brd = 0.;
    //pr = abs(fract(time) - 0.5) * 2.;
    float num = 18.;
    vec3 c1 = vec3(34, 124, 157)/255.;
    vec3 c2 = vec3(23, 195, 178)/255.;
    vec3 c3 = vec3(255, 203, 119)/255.;
    vec3 c4 = vec3(254, 249, 239)/255.;
    vec3 c5 = vec3(254, 109, 115)/255.;
    float cnum = 5.;
    vec3 col = vec3(0);

    vec3 rc = c5;
    vec2 tuv = uv;
    float ins = 0.;
    
    for (float i = 0.; i < num; i++) {
        //uv *= 1.1;
        
        pr = ease3(max(0., fract(-time / 4. - i * 0.) * 1. - 0.));
        
        if (fract(i / 2.) * 2. == 1.){
            //pr = 1. - pr;
        }

        vec2 l1 = line(p1, p2, uv);
        vec2 l2 = line(p2, p3, uv);
        vec2 l3 = line(p3, p1, uv);
        
        ins = min(leftSide(p1, p2, uv), min(leftSide(p2, p3, uv), leftSide(p3, p1, uv)));

        vec3 cc = vec3(0);
        //cc *= vec3(sin(i * 24.12 + 2.) * 0.5 + 0.5, sin(i * 24.12 + 1.) * 0.5 + 0.5, sin(i * 35.23 + 3.) * 0.5 + 0.5);
        if (abs(fract(i/cnum) * cnum - 0.) < 0.1) {
             cc = c1;   
        }
        if (abs(fract(i/cnum) * cnum - 1.) < 0.1) {
             cc = c2;   
        }
        if (abs(fract(i/cnum) * cnum - 2.) < 0.1) {
             cc = c3;   
        }
        if (abs(fract(i/cnum) * cnum - 3.) < 0.1) {
             cc = c4;   
        }
        if (abs(fract(i/cnum) * cnum - 4.) < 0.1) {
             cc = c5;   
        }
        tuv = rotate(uv, i + time);

        //cc += vec3(sin(tuv.x) * 0.5, sin(tuv.y) * 0.5, sin(tuv.x + tuv.y) * 0.5)/2.;
            
        rc = mix(rc, cc, ins);

        brd = max(brd, DrawLine(l1, pr));
        brd = max(brd, DrawLine(l2, pr));    
        brd = max(brd, DrawLine(l3, pr));

        p1 = cp1 + (cp2 - cp1) * pr;
        p2 = cp2 + (cp3 - cp2) * pr;
        p3 = cp3 + (cp1 - cp3) * pr;
        cp1 = p1;
        cp2 = p2;
        cp3 = p3;
        
        //rc += DrawLine(l1, pr) * mix(c1, c2, sin(l1.y + time));
        //rc += DrawLine(l2, pr) * mix(c1, c2, sin(l2.y - time));
        //rc += DrawLine(l3, pr) * mix(c1, c2, sin(l3.y + time));
        
          //if (brd > 0.) break;

    }
    
    col = rc;
    col += brd/1.;

    glFragColor = vec4(col,1.0);
}
