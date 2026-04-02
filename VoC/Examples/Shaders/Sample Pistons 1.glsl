#version 420

// original https://www.shadertoy.com/view/ts3XzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS 0.02
#define SHORTEST_STEP 0.02
#define tt (time*1.)

const float GAPX = 5.;
const float GAPY = 2.7;

vec2 rot(vec2 p, float theta) {
    float s = sin(theta);
    float c = cos(theta);
    return mat2(c, s, -s, c) * p;
}

vec2 dePlane(vec3 p) {
    return vec2(p.y, 0);
}

vec2 sdHexPrism( vec3 p, float off, float subz )
{
    vec2 loc = vec2(
        (p.z - subz) / GAPY + .535*GAPY,
        p.x / GAPX + .5*GAPX
    );
    vec2 flr = floor(loc);
    vec2 flr1 = flr + 1.;
    vec2 fra = fract(loc);
    
    vec2 hexCoord = mix(flr, flr1, clamp(10.*fra - 9., 0.,1.));
    vec2 h = vec2(1,.6+.5*sin(hexCoord.y+tt+off)*sin(hexCoord.x+tt));
    
    
    p.x = mod(p.x + .5*GAPX, GAPX) - .5*GAPX;
    p.z = mod(p.z + .5*GAPY, GAPY) - .5*GAPY;
    
    p.xyz = p.xzy;
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
    return vec2(
        min(max(d.x,d.y),0.0) + length(max(d,0.0)) - .05,
        hexCoord.x + 100.
    );
}

vec2 deBall(vec3 p) {
    p.y -= 1.;
    return vec2(length(p) - 1., 0);
}

vec2 join(vec2 da, vec2 db) {
    return da.x < db.x ? da : db;
}

vec2 DE(vec3 p) {
    float hexCoord = floor(p.x);
    vec2 hexProps = vec2(1,.5+.5*sin(hexCoord));
    
    vec2 a = dePlane(p);
    vec2 b = sdHexPrism(p,0.,0.);
    vec2 c = sdHexPrism(p + vec3(GAPX*.5,0,1), .1, 0.);

    return join(a, join(b, c));
    
}

vec4 resolveMaterial(float material, float dist, vec3 pos, vec3 camPos, vec3 normal) {
    float l = -dot(normalize(pos - camPos), normal);
    vec4 col = vec4(1.7*l);
    
    if (material > .5) {
        col *= vec4(0,.7+.3*cos(material),.7+.3*sin(material),0);
    } else {
        col *= vec4(.7,.8,1.,0);
    }
    
    
    col /= exp(0.09*dist);
    

    return col;
}

void main(void)
{
    vec2 sp = -vec2(.5*resolution.x / resolution.y, .5) + gl_FragCoord.xy/resolution.yy;

    vec3 ro = vec3(20,7.+2.*sin(tt*.7),tt);
    vec3 rd = normalize(vec3(sp,-1));
    
    rd.yz = rot(rd.yz, -0.4 - .1*sin(tt*.7));
    rd.xz = rot(rd.xz, tt*.1);

    vec3 camPos = ro;
    
    float totalDist = 0.;
    vec2 dist = vec2(0);
    float i = 0.;
    for (; i < 50.; ++i) {
        dist = DE(ro);
        if (dist.x < EPS || totalDist > 30.) break;
        dist.x = max(SHORTEST_STEP, dist.x);
        totalDist += dist.x;
        ro += rd * dist.x;
    }
    
    if (dist.x < EPS) {
        vec2 e = vec2(EPS, 0);
        vec3 normal = normalize(vec3(
            DE(ro + e.xyy).x - DE(ro - e.xyy).x,
            DE(ro + e.yxy).x - DE(ro - e.yxy).x,
            DE(ro + e.yyx).x - DE(ro - e.yyx).x));
        
        float ao = (1.-clamp(i/50.,0.,100.));
        
        glFragColor = ao* resolveMaterial(dist.y, totalDist, ro, camPos, normal);
        return;
    }

    glFragColor = vec4(0);
}
