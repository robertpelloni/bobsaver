#version 420

// original https://www.shadertoy.com/view/wlKyWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define hash33(p) fract(sin( (p) * mat3( 127.1,311.7,74.7 , 269.5,183.3,246.1 , 113.5,271.9,124.6) ) *43758.5453123)

// See: https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox(vec3 p, vec3 b) {
    vec3 q= abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x,max(q.y,q.z)),0.0);
}

struct result {
    float dist;
    vec3 color;
};

#define STREET_SZ 2.
result map(vec3 v, vec3 dv) {
    vec2 cell = floor(v.xy);
    result r;
    r.dist = 1e38;
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            vec2 cell2 = cell + vec2(float(dx), float(dy));
            vec3 rand = hash33(vec3(cell2, 0));
            float height = 2.+floor(4.*rand.x);
            if (rand.y > .99) height += 5.;
            
            if (mod(cell2.x, 10.) < STREET_SZ || mod(cell2.y, 10.) < STREET_SZ) height = 0.;
            
            float dist = sdBox(v-vec3(cell2.x+.5, cell2.y+.5, 0), vec3(.3,.3,height));
            if (dist < r.dist) {
                r.dist = dist;
                r.color = vec3(.25+.75*rand.z);
            }
        }
    }
    r.dist = min(r.dist, 1.);

    float mx = mod(v.x, 10.), my = mod(v.y, 10.);
    if (mx < STREET_SZ) { // If we're in an alley, we know we can skip ahead.
        if (dv.x < 0.) r.dist = max(r.dist, -mx/dv.x);
        if (dv.x > 0.) r.dist = max(r.dist, (STREET_SZ-mx)/dv.x);
    }

    if (my < STREET_SZ) { // If we're in an alley, we know we can skip ahead.
        if (dv.y < 0.) r.dist = max(r.dist, -my/dv.y);
        if (dv.y > 0.) r.dist = max(r.dist, (STREET_SZ-my)/dv.y);
    }
    return r;
}

vec4 rayMarch(vec3 v, vec3 dv, vec4 sky) {
    float totalDist = 0.;
    for (int i = 0; i < 800; i++) {
        result r = map(v, dv);
        if (r.dist <= .01) return vec4(r.color, 0);
        v += r.dist*dv;
        totalDist += r.dist;
        if (v.z < 0.1) return vec4(0,0,0,1);
        //if (totalDist >= 100.) break;
        
    }
    if (dv.z < 0. && -v.z/dv.z < 10.) return vec4(0,0,0,1);
    
    return sky;
}

void main(void)
{
    vec2 R = resolution.xy, uv = (gl_FragCoord.xy - 0.5*R)/R.y;
    float t = time*.1, m = mod(t, 2.);
    float cx = 10.*(t - m + 2. * clamp(m, 0., 1.));
    float cy = 10.*(t - m + 2. * clamp(m-1., 0., 1.));
    vec3 camera = vec3(cx, cy, 3.);
    float theta = PI/4. + uv.x*(PI/3.);
    vec3 dv = normalize(vec3(cos(theta), sin(theta), uv.y));
    vec4 sky = vec4(0., .8, 1., 1.);
    glFragColor = rayMarch(camera, dv, sky);
}
