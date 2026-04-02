#version 420

// original https://www.shadertoy.com/view/4ltfW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float fac = 43758.5453123;
    vec2 m = vec2(100., 1.);
    vec2 o = vec2(1., 0.);
    
    float n00 = fract(fac * sin(dot((i + o.yy), m)));
    float n01 = fract(fac * sin(dot((i + o.xy), m)));
    float n10 = fract(fac * sin(dot((i + o.yx), m)));
    float n11 = fract(fac * sin(dot((i + o.xx), m)));
    
    float fx = smoothstep(0., 1., f.x);
    float px0 = mix(n00, n01, fx);
    float px1 = mix(n10, n11, fx);
    
    return mix(px0, px1, smoothstep(0., 1., f.y));
}

float ocean(in vec2 p) {
    float f = 0.;
    
    float speed = 0.5;
    vec2 v01 = vec2( 1.,  0.) * time*speed;
    vec2 v02 = vec2( 0.,  1.) * time*speed;
    vec2 v03 = vec2( 1.,  1.) * time*speed;
    vec2 v04 = vec2(-1.,  0.) * time*speed;
    vec2 v05 = vec2(-1.,  0.) * time*speed;
    vec2 v06 = vec2(-1., -1.) * time*speed;
    
    f += 0.50000*noise(p*1.0  + v01);
    f += 0.25000*noise(p*2.1  + v02);
    f += 0.12500*noise(p*3.9  + v03);
    f += 0.06250*noise(p*8.1  + v04);
    f += 0.03215*noise(p*15.8 + v05);
    f += 0.01608*noise(p*32.3 + v06);
    
    return f;
    
}

float map(in vec3 p) {   
    float o = ocean(p.xz * 0.1) * 2.;
    return p.y + 0.5 + o;
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(0.01, 0.);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
    
}

const vec3 SUN_DIR = normalize(vec3(-0.2, 0.15, -0.8));
const vec3 SUN_COL = vec3(0.9, 0.4, 0.2);

vec3 sky(in vec3 rd, vec3 sunDir, float fac) {
    rd.y = max(0., rd.y);
    vec3 blue = vec3(0.2, 0.6, 0.9)-rd.y*0.85;
    vec3 sunset = mix(blue, SUN_COL*0.9, exp(-rd.y*8.));
    
    vec3 sun = 5.*pow(dot(sunDir, rd), 90.) * SUN_COL;
    return sunset * fac + sun;
}

void main(void)
{
    vec2 p = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    vec3 ro = vec3(0., 0., 0.);
    vec3 ta = vec3(0., 0., 1000.);
    
    vec3 up = vec3(0., 1., 0.);
    vec3 ww = normalize(ta-ro);
    vec3 uu = normalize(cross(ww, up));
    vec3 vv = normalize(cross(uu, ww));
    
    vec3 rd = normalize(vec3(p.x*uu + p.y*vv - 3.0*ww));
    
    float m = -1.;
    float t = 0.;
    float tmax = 300.;
    for(int i = 0; i<512; i++) {
        float h  = map(ro + rd * t);
        if ( h<0.01 ) { m = 1.; break; };
        if ( t>tmax ) break;
        t += h;
    }
    float sunsetFac = mod(time*0.01, 0.2);
    vec3 sunDir = SUN_DIR + vec3(0., -sunsetFac,0.);
    vec3 col = sky(rd, sunDir, 1.-sunsetFac * 4.);
    
    if (m > 0.) {
        vec3 nor = calcNormal(ro + rd * t);
        vec3 ref = reflect(rd, nor);
        vec3 refCol = sky(ref, sunDir, 1.-sunsetFac);
        
        float d = dot(sunDir, nor);
        vec3 dif = refCol*clamp(d, 0., 1.);
        vec3 amb = vec3(0.01, 0.03, 0.08);
        vec3 spec = refCol*pow(clamp(d+0.9, 0.,1.), 200.0);
        
        vec3 oceanCol = amb + mix(dif, spec, 0.4);
        
        col = mix(oceanCol, col, t/tmax);
    }
    
    col = pow(col, vec3(0.4545));
    
    // fade out
    col *= smoothstep(0., 0.1, 1.-5.*sunsetFac);
    // fade in
    col *= smoothstep(0., 0.01, sunsetFac);
    
    
    glFragColor = vec4(col,1.0);
}
