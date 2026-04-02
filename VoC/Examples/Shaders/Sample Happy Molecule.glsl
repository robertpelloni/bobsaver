#version 420

// original https://www.shadertoy.com/view/3dt3R4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool sphereIsect(vec3 p, vec3 sc, float sr)
{
    return distance(p, sc) <= sr;
}

vec3 sphereNorm(vec3 p, vec3 sc)
{
    return normalize(p - sc);
}

vec3 sphereRay(vec3 rd, vec3 ro, vec3 sc, float sr)
{
    vec3 dv = sc - ro;
    
    float a = abs(dot(normalize(rd), normalize(dv)));
    
    float d = length(dv);
    float p = d * a - sqrt(d*d*a*a - d*d + sr*sr);
    
    vec3 sp = normalize(rd) * p;
    
    vec3 r = sp - dv;
    
    if (length(r) > 0.0) {
        return sp;
    }
    
    return vec3(.0);
}

vec3 minRay(vec3 p, vec3 pn)
{
    if (length(pn) > 0.0 && (length(pn) < length(p) || length(p) == 0.0))  {
        return pn;
    }
    return p;
}

bool cmpRay(vec3 p, vec3 pn)
{
    if (length(pn) > 0.0 && (length(pn) < length(p) || length(p) == 0.0))  {
        return true;
    }
    return false;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x*2. - resolution.x, 
                   gl_FragCoord.y*2. - resolution.y);
    uv /= resolution.y;

    vec3 col = vec3(sin(time + uv.x * uv.y * 2.) * 0.5, 0.0, cos(time + uv.y * uv.x * 2.));
    col *= vec3(0.1, 0.0, 0.2);
    
    vec3 sc1 = vec3(0.0, 0.0, 1.5);
    float sr1 = 1.0;
    
    vec3 sc2 = vec3(0.8 * cos(time * 0.8), 
                    0.4 * (sin(time * 0.3) + cos(time * 0.5)), 
                    0.8 * sin(time * 0.8) + 1.5);
    float sr2 = 0.35 + 0.03 * cos(time * 8.);
    
    vec3 sc3 = vec3(0.8 * cos(time * 0.8 + 2.), 
                    0.4 * (sin(time * 0.2) + cos(time * 0.7)), 
                    0.8 * sin(time * 0.8 + 2.) + 1.5);
    float sr3 = 0.35 + 0.03 * cos(time * 8.);
    
    vec3 sc4 = vec3(0.8 * cos(time * 0.8 + 4.), 
                    0.4 * (sin(time * 0.88) - cos(time * 0.1)), 
                    0.8 * sin(time * 0.8 + 4.) + 1.5);
    float sr4 = 0.35 + 0.03 * cos(time * 8.);
    
    vec3 rd = vec3(uv.x, uv.y, 1.5);
    rd = normalize(rd);
    vec3 ro = vec3(0.0, 0.0, -0.5);
    
    vec3 p = vec3(0.);
    
    vec3 pn = sphereRay(rd + vec3(0.02*sin(time * 10.0),.0,.0), 
                        ro + vec3(0.,0.02*sin(time * 8.0),
                                  0.02*cos(time * 5.0)), sc1, sr1);
    
    if (cmpRay(p, pn)) {
        p = pn;
        col = (sphereNorm(p, sc1)*.5 + .5);
        col *= vec3(0.1, 0.1, 1.0);
    }
    
    pn = sphereRay(rd, ro, sc2, sr2);
    
    if (cmpRay(p, pn)) {
        p = pn;
        col = sphereNorm(p, sc2)*.5 + .5;
        float f = 0.7 + (length(p - sc2) - sr2);
        col *= f * f * f;
        col *= exp(col) * exp(col);
        col *= vec3(1., 0.3, 0.1);
    }
    
    pn = sphereRay(rd, ro, sc3, sr3);
    
    if (cmpRay(p, pn)) {
        p = pn;
        col = sphereNorm(p, sc3)*.5 + .5;
        float f = 0.7 + (length(p - sc3) - sr3);
        col *= f * f * f;
        col *= exp(col) * exp(col);
        col *= vec3(1., 0.3, 0.1);
    }
    
    pn = sphereRay(rd, ro, sc4, sr4);
    
    if (cmpRay(p, pn)) {
        p = pn;
        col = sphereNorm(p, sc4)*.5 + .5;
        float f = 0.7 + (length(p - sc4) - sr4);
        col *= f * f * f;
        col *= exp(col) * exp(col);
        col *= vec3(1., 0.3, 0.1);
    }

    glFragColor = vec4(col,1.0);
}
