#version 420

// original https://www.shadertoy.com/view/wsySDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define GRID 0.5
#define THICKNESS 0.05
#define FDIST 0.5

#define TOTAL_ITERS 100
#define RAYMARCH_EPS 0.001

#define OCCUPANCY 0.5

#define FOV 1.55

vec3 rainbow(float t) {
    return vec3(sin(t), cos(t), -sin(t)) * .5 + .5;
}

float traceCell(in vec3 ro, in vec3 rd) {
    vec3 dr = 1.0/rd;
    vec3 n = ro * dr;
    vec3 k = GRID * abs(dr);
    
    vec3 pout =  k - n;
    return min(pout.x, min(pout.y, pout.z));
}

float noise(in vec3 P)
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Value3D.glsl

    // establish our grid cell and unit position
    vec3 Pi = floor(P);
    vec3 Pf = P - Pi;
    vec3 Pf_min1 = Pf - 1.0;

    // clamp the domain
    Pi.xyz = Pi.xyz - floor(Pi.xyz * ( 1.0 / 69.0 )) * 69.0;
    vec3 Pi_inc1 = step( Pi, vec3( 69.0 - 1.5 ) ) * ( Pi + 1.0 );

    // calculate the hash
    vec4 Pt = vec4( Pi.xy, Pi_inc1.xy ) + vec2( 50.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    vec2 hash_mod = vec2( 1.0 / ( 635.298681 + vec2( Pi.z, Pi_inc1.z ) * 48.500388 ) );
    vec4 hash_lowz = fract( Pt * hash_mod.xxxx );
    vec4 hash_highz = fract( Pt * hash_mod.yyyy );

    //    blend the results and return
    vec3 blend = Pf * Pf * Pf * (Pf * (Pf * 6.0 - 15.0) + 10.0);
    vec4 res0 = mix( hash_lowz, hash_highz, blend.z );
    vec4 blend2 = vec4( blend.xy, vec2( 1.0 - blend.xy ) );
    return dot( res0, blend2.zxzx * blend2.wwyy );
}

vec3 cellmod(in vec3 ro) {
    return mod(ro, GRID) - GRID*0.5;
}

vec3 cellID(in vec3 ro) {
    return floor(ro/GRID);
}

float occupancy(in vec3 id) {
    return noise(id);
}

// LOD SDF: skip evaluating details if the current distance OR the distance to the exit is 
float longpipe(vec3 ro, float mindist, float bound) {
    float dist = length(ro.yz) - THICKNESS;
    if (dist < min(mindist, bound)) {
        // complex stuff
        dist += 0.005*GRID*(cos(ro.x*20. * 3.14159)+1.);
    } 
    // bounding volume
    return dist;
}

float torus(vec3 ro) {
    float xydist = length(ro.xy) - 0.5 * GRID;
    return length(vec2(ro.z, xydist))-THICKNESS;
}

vec2 march(in vec3 ro, in vec3 rd) {
    vec3 id = cellID(ro);
    vec3 dr = GRID/rd;
    vec3 rs = sign(rd);
    vec3 tr = (0.5 * rs - cellmod(ro)/GRID) * dr; // exiting t
    vec3 t = vec3(0.); // current t
    int i;
    vec2 disp = vec2(1., 0.);
    for (i=0; i<TOTAL_ITERS; i++) {
        // DDA traversal
        if (occupancy(id) > OCCUPANCY) {
            // check neighbors
            vec3 n_pos = step(OCCUPANCY, vec3(occupancy(id+disp.xyy),
                                                occupancy(id+disp.yxy),
                                                occupancy(id+disp.yyx)));
            vec3 n_neg = step(OCCUPANCY, vec3(occupancy(id-disp.xyy),
                                                occupancy(id-disp.yxy),
                                                occupancy(id-disp.yyx)));
            vec3 n_axes = n_pos + n_neg;
            vec3 diff_axes = n_pos - n_neg;
            float total = n_axes.x + n_axes.y + n_axes.z;
            if (total > 0.5) {
                
                
                // raymarching
                float t0 = min(t.x, min(t.y, t.z));
                float maxdist = min(tr.x, min(tr.y, tr.z)) - t0;
                vec3 ro0 = ro + t0 * rd - (id+0.5) * GRID;
                float tt = 0.;
                for (; i<TOTAL_ITERS; i++) {
                    vec3 pos = ro0 + tt * rd;
                    float dist = 1e6;
                    float bound = maxdist - tt;
                    if (n_axes.x > 1.5) {
                        dist = min(dist, longpipe(pos, dist, bound));
                    }
                    if (n_axes.y > 1.5) {
                        dist = min(dist, longpipe(pos.yzx, dist, bound));
                    }
                    if (n_axes.z > 1.5) {
                        dist = min(dist, longpipe(pos.zxy, dist, bound));
                    } 
                    for (int j=0; j<2; j++) {
                        if (abs(n_axes[j]-1.)<0.5) {
                            for (int k=j+1; k<3; k++) {
                                if (abs(n_axes[k]-1.)<0.5) {
                                    vec3 u = vec3(0.);
                                    u[j] = diff_axes[j];
                                    vec3 v = vec3(0.);
                                    v[k] = diff_axes[k];
                                    vec3 w = cross(u, v);
                                    mat3 rot = mat3(u, v, w);
                                    mat3 rotT = transpose(rot);
                                    vec3 pos_local = rotT * (pos -(v + u) * 0.5*GRID);
                                    dist = min(dist, torus(pos_local));
                                }
                            }
                        }
                    }
                    
                    tt += dist;
                    if (abs(dist) < RAYMARCH_EPS) {
                        return vec2(tt + t0, i);
                    }
                    if (tt > maxdist || tt < 0.) {
                        break;
                    }
                }
            }
        }
        t = tr;
        vec3 n = step(tr.xyz, tr.zxy) * step(tr.xyz, tr.yzx) * rs;
        tr += dr * n;
        id += n;
    }
    return vec2(min(t.x, min(t.y, t.z)), i);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.x * FOV;
    vec3 eye = vec3(5.*time, 0.1, 0.1);
    vec3 w = normalize(vec3(1., sin(.5*time), cos(time*.2)));
    vec3 u = normalize(cross(w, vec3(0., 0., 1.)));
    vec3 v = cross(u, w);
    vec2 c = cos(uv);
    vec2 s = sin(uv);
    vec3 rd = normalize(s.x * c.y * u + s.y * v + c.x * c.y * w);
    
    vec2 t = march(eye, rd);
    
    glFragColor = vec4(pow(rainbow(t.x/2.+1.5) * vec3(1.-t.y/100.), vec3(0.75)),1.0);
}
