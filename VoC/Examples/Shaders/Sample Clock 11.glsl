#version 420

// original https://www.shadertoy.com/view/lsSBWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform vec4 date;

out vec4 glFragColor;

vec2 sd_line(vec2 pos, vec2 a, vec2 b) {
    pos -= a;
    vec2 d = b-a;
    float l = length(d);
    d /= l;
    
    float t = dot(d,pos);
    vec2 p = d*clamp(t,0.0,l);
    vec2 perp = vec2(d.y,-d.x);
    
    return vec2(length(pos-p), dot(pos,perp));
}

float abs_min(float a, float b) {
     return abs(a) < abs(b) ? a : b;   
}

vec2 lmin(vec2 a, vec2 b) {
    if(abs(a.x-b.x) < 0.0001) {
      return a.y > b.y ? a : b;
    }
    
    return a.x < b.x ? a : b;
}

float to_sd(vec2 x) {
     return x.x * sign(x.y);   
}

float sd_diamond(vec2 pos, vec2 tail, vec2 tip, float width, float mid) {
    vec2 d = tip-tail;
    vec2 p = vec2(d.y,-d.x) * width * 0.5;
    vec2 m = d*mid+tail;
    
    vec2 la = sd_line(pos,tail,m+p);
    vec2 lb = sd_line(pos,m+p,tip);
       vec2 lc = sd_line(pos,tip,m-p);
    vec2 ld = sd_line(pos,m-p,tail);
    
    
    return to_sd(lmin(lmin(la,lb),lmin(lc,ld)));
}

vec2 to_polar(vec2 x) {
    return vec2(length(x), atan(-x.y, -x.x) + 3.14159);
}

vec2 from_polar(vec2 x) {
     return vec2(cos(x.y),sin(x.y)) * x.x;   
}

vec2 radial_repeat(vec2 pos, float count) {
    float offset = 0.5/count;
    pos = to_polar(pos);
    pos.y /= 2.0*3.14195;
    pos.y += offset;
       pos.y *= count;
       pos.y = fract(pos.y);
       pos.y /= count;
    pos.y -= offset;
    pos.y *= 2.0*3.14195;
    pos = from_polar(pos);
    return pos;
}

vec2 rotate(vec2 pos, float turns) {
     pos = to_polar(pos);
    pos.y += turns * 2.0 * 3.14195;
    return from_polar(pos);
}

float gear(vec2 uv, float inner, float outer, float width, float mid, float teeth, float turns) {
    uv = rotate(uv,turns);
    uv = radial_repeat(uv, teeth);
    
    
       
    float d = 0.05;
    return sd_diamond(uv, vec2(inner,0.0), vec2(outer,0.0), width, mid);
}

float hand(vec2 uv, float len, float width, float mid, float turns) {
    turns = fract(turns);
    uv = rotate(uv,turns-0.25);
    return sd_diamond(uv, vec2(0.0,0.0), vec2(len,0.0), width, mid);
}

float cutoff(float sd) {
    
    sd *= 150.0;
    return smoothstep(1.0,0.0,sd);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5) / min(resolution.x, resolution.y) * 2.0;

    float t = date.w;
    float m = t/60.0;
    float h = m/60.0;
    
    
    float pulse = pow(fract(t)*1.00,15.0);
    
    float face = abs(length(uv)-1.0)*0.8;
    face = min(face, gear(uv, 0.8, 0.9, 0.3, 0.8, 12.0, 0.0));
    face = min(face, gear(uv, 0.9, 0.95, 0.3, 0.8, 60.0, 0.0));
    
    float secHand = hand(uv, 0.97,0.05, 0.1, floor(t)/60.0 + pulse/60.0);
    float minHand = hand(uv, 0.90,0.1, 0.8, floor(m)/60.0);
    float hourHand = hand(uv, 0.75,0.1, 0.8, floor(h)/12.0);
    
    vec3 col = vec3(1.0);
    col = mix(col, vec3(0.0), cutoff(face));
    col = mix(col, vec3(0.0), cutoff(minHand));
    col = mix(col, vec3(0.0), cutoff(hourHand));
    col = mix(col, vec3(1.0,0.0,0.0), cutoff(secHand));
    
    glFragColor = vec4(col,1.0);
}
