#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define obj(d, i) if (d < m) { m = d; id = i; }

float map(vec3 p, out int id) {
    
    float m = 1e3;
    
    
    float d = (2. - abs(p.y));
    obj(d, 1);
    
    p.xz = mod(p.xz, 4.) - 2.;
    
    d = length(p) - 1.;
    obj(d, 2);
    
    return m;

}
 
vec3 normal(vec3 p) {
  float e = 0.01;
    int id;
  return normalize(vec3(
    map(p + vec3(e, 0, 0), id) - map(p - vec3(e, 0, 0), id),
  map(p + vec3(0, e, 0), id) - map(p - vec3(0, e, 0), id),
  map(p + vec3(0, 0, e), id) - map(p - vec3(0, 0, e), id)
  ));
}

void main() {
    
    
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec3 col = vec3(0.);
    
    vec3 ro = vec3(0, 0, time);
    vec3 rd = vec3(uv, 1);
    vec3 p = vec3(0);
    
    float t = 0.;
    int id;
    for (int i = 0; i < 128; i++) {
        p = ro + rd * t;
        float d = map(p, id);
        t += 0.5 * d;
    }

    vec3 nor = normal(p);
    float diff = max(dot(normalize(ro - p), nor), 0.);
    float itter = 1. / (1. + t * t * 0.04);
    
    if (id == 1) {
        vec2 f = mod(p.xz, 4.) - 2.;
        col += sign(sin(p.z * 6.) * cos(p.x * 6.)) * diff;
        
        
    }
    
    else if (id == 2) {
        
        col += 0.5 * vec3(1, 0, 0);
        col += 0.5 * diff;
        
        int rid;
        vec3 rro = p;
        vec3 rrd = normalize(reflect(rd, nor));
        float rt = 0.1;
        vec3 rp = vec3(0);
        for (int i = 0; i < 32; i++) {
            rp = rro + rrd * rt;
            float d = map(rp, rid);
            rt += 0.5 * d;
        }
        
        vec3 rnor = normal(rp);
        float rdiff = max(dot(normalize(rro - rp), rnor), 0.);
        
        float ritter = 1. / (1. + rt * rt * 0.25);
        col *= ritter;
        
        if (rid == 1) {    
            col += sign(sin(rp.z * 6.) * cos(rp.x * 6.)) * rdiff;
            col *= ritter;
        }
        
        if (rid == 2) {
            
            col += vec3(1., 0., 0.) * 0.2;
            col += rdiff;
            col *= ritter;
            
            int rrid;
            vec3 rrro = rp;
            vec3 rrrd = reflect(rrd, rnor);
            float rrt = 0.5;
            vec3 rrp = vec3(0);
            for (int i = 0; i < 32; i++) {
            rrp = rrro + rrrd * rrt;
            float d = map(rrp, rrid);
                rrt += 0.5 * d;
            }
    
            vec3 rrnor = normal(rrp);
            float rrdiff = max(dot(normalize(rrro - rrp), rrnor), 0.);
            
            float rritter = 1. / (1. + rrt * rrt * 1.);
            col *= rritter;
            
            if (rrid == 1) {
                col += sign(sin(rrp.z * 6.) * cos(rrp.x * 6.)) * diff * vec3(1, 0, 0);
            }
            
            if (rrid == 2) {
                col += vec3(1., 0., 0.) * 0.2;
                col += diff * 0.2;
            }
            
            col *= rritter;
        
            
        }
        
    }
    
    if (t > 1000.) col = vec3(0.5);
    
    col *= itter;
    

    glFragColor = vec4(col, 1.);

}
