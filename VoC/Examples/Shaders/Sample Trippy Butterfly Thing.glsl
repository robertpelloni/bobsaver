#version 420

// original https://www.shadertoy.com/view/slcSW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

float thc(float a, float b) {
    return tanh(a * cos(b)) / tanh(a);
}

float ths(float a, float b) {
    return tanh(a * sin(b)) / tanh(a);
}

vec3 thc(float a, vec3 b) {
    return tanh(a * cos(b)) / tanh(a);
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float h21 (float a, float b, float sc) {
    a = mod(a, sc); b = mod(b, sc);
    return fract(sin(dot(vec2(a, b), vec2(12.9898, 78.233)))*43758.5453123);
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

vec2 pnt(vec2 ipos, float sc) {
    float h = h21(ipos.x, ipos.y, sc);
    float t = time + 10. * h;
    float k = 1.5 +  h;
    return 0.4 * vec2(thc(4. * (1.-h), 100. + k * t), 
                      ths(4. * h, 100. + (1.-k) * t));
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b * cos(6.28318*(c*t+d) );
}

float test(vec2 p) {
    return h21(floor(h21(p) + time) + 0.01 * p);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/ resolution.y;
    vec2 ouv = uv;
    ouv.y += 0.05 * cos(time);
    vec2 ms = (mouse*resolution.xy.xy - 0.5 * resolution.xy)/ resolution.y;
    //uv += 3. + 0.04 * time;
    
    float a = atan(uv.y, uv.x);
    float r = length(uv); 
    //uv = vec2(4. * a/pi, log(r) - 0.1 * time);
    
    float c = 2.;
    // cant scale dynamically because sc used in h21 (bad)
    float sc = 50.;// + 1./length(ouv-ms);
    vec2 fpos = fract(sc * uv) - 0.;
    vec2 ipos = floor(sc * uv) + 0.5;    
    
    // Generate values for each corner of uv (sloppy)
    float l  = h21(ipos.x + 1., ipos.y,      c * sc);
    float t  = h21(ipos.x,      ipos.y + 1., c * sc);
    float tl = h21(ipos.x + 1., ipos.y + 1., c * sc);
    float id = h21(ipos.x,      ipos.y,      c * sc);

    vec2 lp = ipos + vec2(1.,0.);
    vec2 tp = ipos + vec2(0.,1.);
    vec2 tlp = ipos + vec2(1.);
    vec2 idp = ipos;

    l = test(lp);
    t = test(tp);
    tl = test(tlp);
    id = test(idp);
    
    //float v = h21(floor(h21(ipos) + time) + 0.01 * ipos);

    // Smooth fpos completely, so v noise looks better
    vec2 sfpos = fpos * fpos * (3. - 2. * fpos);
    
    // Smooth the grid uvs so different uvs meet continuously on the edges
    //fpos = mix(fpos, fpos * fpos * (3. - 2. * fpos), 0.5 * thc(4., time));
    
    // Box lerp between the corner values to get a radius value for this pixel
    float v = l  * sfpos.x      * (1.-sfpos.y)
             + t  * (1.-sfpos.x) * sfpos.y
             + tl * sfpos.x      * sfpos.y
              + id * (1.-sfpos.x) * (1.-sfpos.y);
            
    uv *= mix(0.6, 0.2, 0.5 + 0.5 * thc(4., v * 10. + time));// + 0.5 * cos(v + time);
    vec2 p = vec2(thc(2., 0.2 * v + 8. * abs(uv.x) + 2. * a - time), 
                  ths(2., 0.2 * v + 8. * abs(uv.y) - 3. * a - time));
    uv.x *= thc(4., time + 8. * p.x);
    uv.y *= ths(4., time + 8. * p.y);
    float d = length(uv/p);
    float k = 0.1 * v;
    float s = smoothstep(-k,k, -d + 0.15);
    s *= 4. * s * s;
    s = clamp(s, 0., 1.);
    vec3 col = vec3(s);
    vec3 e = vec3(1.);
    col = s * pal(thc(2., 0.1 * h21(ipos) + 10. * r + 4. * length(p) - time), 
                    e, e, e, mix(0., 0.5, 0.5 + 0.5 * cos(length(p)*32. + time)) + 0.5 * vec3(0.,0.33,0.66));
    
    //col *= smoothstep(-v * 0.2, v, -length(ouv) + 0.25);
    col *= mix(smoothstep(-v * 0.2, v, -length(ouv) + 0.25), 1., 0.5 + 0.5 * cos(0.8 * time));
    glFragColor = vec4(col, 1.); //vec4(v);
}
