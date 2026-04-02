#version 420

// original https://www.shadertoy.com/view/tdSBRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(3213.213123, 7879.789321)))*321312.890);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 ii = i+1.0;
    vec2 f = fract(p);
    
    f = smoothstep(0.0, 1.0, f);
    
    return mix(mix(rand(vec2(i.x+0.0, i.y+0.0)), rand(vec2(i.x+1.0, i.y+0.0)), f.x),
               mix(rand(vec2(i.x+0.0, i.y+1.0)), rand(vec2(i.x+1.0, i.y+1.0)), f.x),
               f.y);
}

float map(vec3 p) {
    float d = 1e10;
    vec3 q;
    
    q = p;
    q.y -= -5.0;
    d = min(d, q.y + (noise(q.xz*3.0)*0.05)+noise(q.xz*0.5+vec2(13213.2))*0.5 );
    
    q = p;
    q.y -= 25.0;
    d = min(d, -q.y + (noise(q.xz*3.0)*0.05)+noise(q.xz*0.5+vec2(13213.2))*0.5 );
    
    q = p;
    q.y -= -2.5;
    q.xz = mod(q.xz, 6.0) - 3.0;
    d = min(d,
            sdRoundBox(q, vec3(0.2, 100.0, 0.2), 0.2) +
            noise( (p.yz+p.xy) )*0.1 +
            noise( (p.yz+p.xy)*20.0 )*0.01);
    
    return d;
}

vec3 getNormal(vec3 p) {
    vec2 eps = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p+eps.xyy) - map(p-eps.xyy),
        map(p+eps.yxy) - map(p-eps.yxy),
        map(p+eps.yyx) - map(p-eps.yyx)));
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.yy;
    vec3 cPos = vec3(0.0, 0.0, -5.0);
    
    cPos = vec3(sin(time*0.5), 0.3+cos(time*0.4)*0.2, cos(time*0.5));
    cPos *= 10.5;
    
    vec3 cTar = vec3(0.0, 0.0, 0.0);
    cTar = vec3(sin(time), cos(time*0.7)*0.5+0.5, 0.0);
    cTar *= 10.5;
    
    
    vec3 cDir = normalize(cTar - cPos);
    vec3 wU = vec3(0.0, 1.0, 0.0);
    vec3 cR = cross(cDir, wU);
    vec3 cU = cross(cR, cDir);
    
    vec3 rd = normalize(p.x*cR + p.y*cU + cDir);
    vec3 ro = cPos;
    
    float t = 0.;
    vec3 rp;
    for(int i=0; i<99; i++) {
        rp = ro + rd*t;
        float d = map(rp);
        
        t += d;
    }
    
    float mt = time;
    float ph = fract(mt);
    
    vec3 col = vec3(0.0);
    vec3 lDir = normalize(vec3(0.5, 0.5, -0.5));
    float diff = max(0.0, dot(lDir, getNormal(rp)));

    col += (diff+0.1)*cDir*exp(-3.0*t*t)*100.0;

    float decay = exp(-0.1*t);
    col += decay*0.01;
    col += exp(-100.0*abs(fract(rp*5.0+0.1)-0.5))*decay;
    col += max(0.0, exp(-500.0*abs( fract(t*0.5)-ph )))*decay*vec3(0.3, 1.0, 0.4)*2.5;
    col = clamp(col, 0.0, 1.5);
    
    col = pow(col, vec3(0.45));
    col -= ( 1.0-exp(-0.2*length(p)) )*0.2;
    glFragColor = vec4(col,1.0);
}
