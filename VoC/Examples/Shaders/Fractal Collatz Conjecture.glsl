#version 420

// original https://www.shadertoy.com/view/4tBBRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// created by Trashe725

#define AA 3
#define pi 3.14159265358979323846
#define maxIter 100
#define maxThres 10000.

// from julesb
// github: https://github.com/julesb/glsl-util/blob/master/complexvisual.glsl

vec2 cx_add(vec2 a, float b) { return vec2(a.x+b, a.y); }
vec2 cx_mul(vec2 a, vec2 b) { return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x); }
vec2 cx_cos(vec2 a) { return vec2(cos(a.x) * cosh(a.y), -sin(a.x) * sinh(a.y)); }
vec2 cx_sin(vec2 a) { return vec2(sin(a.x) * cosh(a.y), cos(a.x) * sinh(a.y)); }

vec2 rot(vec2 v, float ang)
{
    float c = cos(ang);
    float s = sin(ang);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

vec3 render(vec2 gl_FragCoord, float time)
{
    //zoom
    float sc = 0.003;
    vec2 ce = vec2(-0.703, 0);
    float zoom = time * 4.;
    sc = sc * pow(0.9, zoom);
    
    //rotate
    vec2 fc = rot((-resolution.xy + 2.0 *gl_FragCoord) / resolution.y, time/3.14);
    vec2 z = ce + sc * fc;
    vec2 dz = vec2(1.0, 0.0);
    
    vec2 lz = z;
    vec2 ldz = dz;
    
    int iter = 0;
    while(iter < maxIter && dot(z,z) < maxThres){
        lz = z;
        ldz = dz;
        vec2 piz = pi*z;
        dz = cx_add( pi*cx_mul(cx_sin(piz), cx_add(z*4., 2.))-5.*cx_cos(piz), 7.)/4.;
        z = ( cx_add(z*7., 2.) - cx_mul(cx_add(z*5., 2.), cx_cos(piz)) )/4.;
        ++iter;
    }
    
    //color
    if (iter < maxIter){
        float dzlog = log(length(ldz));
        float aslog = abs(sin(dzlog/5.0));
        float inner = clamp(aslog-0.2, 0.0, 0.5)*2.;
        float outer = 1.0 - smoothstep(0.5, 0.8, aslog-0.2);
        float grad = sin(smoothstep(0.3, 0.7, aslog-0.2)*pi);
        float fiter = float(iter);
        vec3 col1 = vec3(abs(sin(fiter/5.)),
                        abs(sin(fiter/5.+pi/4.0)),
                        abs(cos(fiter/5.0)));
        //vec3 col2 = vec3(abs(sin(fiter/5.+pi/6.0)),
        //                abs(sin(fiter/5.+pi/6.0)),
        //                abs(cos(fiter/5.+pi/6.0)));
        //return mix(col1 + grad*col1*0.2, col2, grad*0.6) * inner * outer;
        return (col1 + grad*col1*0.2) * inner * outer;
    }else{
        return vec3(0.);
    }
}

void main(void)
{
    vec3 col = vec3(0.0);
    float time2 = sin(time/4.)*13.;
#ifdef AA
    for(int m=0;m<AA;++m){
        for(int n=0;n<AA;++n){
            vec2 px = gl_FragCoord.xy + vec2(float(m), float(n))/float(AA);
            col += render(px, time2);
        }
    }
    
    col /= float(AA*AA);
#else
    col = render(gl_FragCoord.xy, time2);
#endif
    glFragColor = vec4(col, 1.0);
}
