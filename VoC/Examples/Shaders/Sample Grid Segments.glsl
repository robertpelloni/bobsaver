#version 420

// original https://www.shadertoy.com/view/NtG3DV

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

// idk what to call this
vec2 func(float t) {
    return vec2(.5 + .5 * cos(t));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/ resolution.y;
    vec2 ouv = uv;
    vec2 ms = (mouse*resolution.xy.xy - 0.5 * resolution.xy)/ resolution.y;
    //uv += 2. + 0.04 * time;
    
    float a = atan(uv.y, uv.x);
    float r = length(uv); 
    uv = vec2(4. * a/pi, log(r) - 0.1 * time);
    
    float c = 100.;
    // cant scale dynamically because sc used in h21 (bad)
    float sc = 5.;// + 1./length(ouv-ms);
    vec2 fpos = fract(sc * uv) - 0.;
    vec2 ipos = floor(sc * uv) + 0.5;    
    
    // Generate values for each corner of uv (sloppy)
    // (transitions between different noise sets)
    float l  = h21(ipos.x + 1., ipos.y,      c * sc);
    float t  = h21(ipos.x,      ipos.y + 1., c * sc);
    float tl = h21(ipos.x + 1., ipos.y + 1., c * sc);
    float id = h21(ipos.x,      ipos.y,      c * sc);

    // Smooth fpos completely, so v noise looks better
    vec2 sfpos = fpos * fpos * (3. - 2. * fpos);
    
    // Smooth the grid uvs so different uvs meet continuously on the edges
    //fpos = mix(fpos, fpos * fpos * (3. - 2. * fpos), 0.5 * thc(4., time));
    
    // Box lerp between the corner values to get a radius value for this pixel
    float v = l  * sfpos.x      * (1.-sfpos.y)
             + t  * (1.-sfpos.x) * sfpos.y
             + tl * sfpos.x      * sfpos.y
              + id * (1.-sfpos.x) * (1.-sfpos.y);
    
    // shift fpos correctly
    fpos -= 0.5;
    
    // moving points for each cell
    vec2 p = pnt(ipos, sc);

    vec2 pl = -vec2(1.,0.) + pnt(ipos - vec2(1.,0.), sc);
    vec2 pr =  vec2(1.,0.) + pnt(ipos + vec2(1.,0.), sc);
    vec2 pt = -vec2(0.,1.) + pnt(ipos - vec2(0.,1.), sc);
    vec2 pb =  vec2(0.,1.) + pnt(ipos + vec2(0.,1.), sc);
    
    // used to change intensity of each segment
    float rl = h21(vec2((ipos.x - 1.) * ipos.x, ipos.y));
    float rr = h21(vec2((ipos.x + 1.) * ipos.x, ipos.y));
    float rt = h21(vec2(ipos.x, (ipos.y - 1.) * ipos.y));
    float rb = h21(vec2(ipos.x, (ipos.y + 1.) * ipos.y));   
    
    // draw half of each segment for each cell
    float dl = sdSegment(fpos, p, pl);
    float dr = sdSegment(fpos, p, pr);
    float dt = sdSegment(fpos, p, pt);
    float db = sdSegment(fpos, p, pb);
        
    // Outline line segments, scale with v
    // (m = thickness of line, n = thickness of outline)  
    float m = 0.05 + 0.07 * v;
    float ml = m + 0.1 * cos(length(p - pl));
    float mr = m + 0.1 * cos(length(pr - p));
    float mt = m + 0.1 * cos(length(p - pt));
    float mb = m + 0.1 * cos(length(pb - p));
    float mm = 0.1;
    ml = min(ml, mm);mr = min(mr, mm);mt = min(mt, mm);mb = min(mb, mm);
      
    float n = 0.18;
    float sl = rl * (step(0.,ml - dl)-step(0., n * ml - dl));
    float sr = rr * (step(0.,mr - dr)-step(0., n * mr - dr));
    float st = rt * (step(0.,mt - dt)-step(0., n * mt - dt));
    float sb = rb * (step(0.,mb - db)-step(0., n * mb - db));
    
    /*
    float n2 = 0.08 * h21(uv);  
    float sl = rl * (smoothstep(-n2,n2,ml - dl)-smoothstep(-n2,n2, n * ml - dl));
    float sr = rr * (smoothstep(-n2,n2,mr - dr)-smoothstep(-n2,n2, n * mr - dr));
    float st = rt * (smoothstep(-n2,n2,mt - dt)-smoothstep(-n2,n2, n * mt - dt));
    float sb = rb * (smoothstep(-n2,n2,mb - db)-smoothstep(-n2,n2, n * mb - db));
    //*/
    float s = max(max(sl, sr), max(st, sb));
    
    // Segment colors
    vec3 col = 1. * s + s * pal(0.5 * v + r * 0.5 - 0.3 * time, vec3(0.), vec3(1.), vec3(1.),  
                  2. * r * cos(s + 0.15 * time) * vec3(0.,0.33,0.66));

    col = clamp(8. * pow(length(ouv), 2.) * col, vec3(0.), col);
    
    glFragColor = vec4(col, 1.); //vec4(v);
}
