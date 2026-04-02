#version 420

// original https://www.shadertoy.com/view/dtB3z3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float eyeDist = 0.5;
const bool delag = false;

//Light, neutral colors seem to work best.
const vec3 fogColor = vec3(0.8);

//The smaller the number, the less reflective the surface.
const float reflectiveness = 0.3;

//Dave_Hoskins' Hash Without Sine
float random3(vec3 p){
    p = fract(p*0.1031);
    p += dot(p, p.zyx + 31.32);
    return (fract((p.x + p.y)*p.z)*2.0) - 1.0;
}

float perlinNoise(vec3 p){
    vec3 cellPos = floor(p);
    vec3 cellFract = fract(p);
    vec3 cellMix = cellFract*cellFract*(3.0 - 2.0*cellFract);
    float value;

    vec3 blf = vec3(random3((cellPos + vec3(0, 0, 0))*1.0));
    vec3 brf = vec3(random3((cellPos + vec3(1, 0, 0))*1.0));
    vec3 trf = vec3(random3((cellPos + vec3(1, 1, 0))*1.0));
    vec3 tlf = vec3(random3((cellPos + vec3(0, 1, 0))*1.0));

    vec3 blb = vec3(random3((cellPos + vec3(0, 0, 1))*1.0));
    vec3 brb = vec3(random3((cellPos + vec3(1, 0, 1))*1.0));
    vec3 trb = vec3(random3((cellPos + vec3(1, 1, 1))*1.0));
    vec3 tlb = vec3(random3((cellPos + vec3(0, 1, 1))*1.0));

    value = mix(
        mix(
            mix(dot(cellFract - vec3(0, 0, 0), blf), dot(cellFract - vec3(1, 0, 0), brf), cellMix.x),
            mix(dot(cellFract - vec3(0, 1, 0), tlf), dot(cellFract - vec3(1, 1, 0), trf), cellMix.x),
            cellMix.y
        ),
        mix(
            mix(dot(cellFract - vec3(0, 0, 1), blb), dot(cellFract - vec3(1, 0, 1), brb), cellMix.x),
            mix(dot(cellFract - vec3(0, 1, 1), tlb), dot(cellFract - vec3(1, 1, 1), trb), cellMix.x),
            cellMix.y
        ),
        cellMix.z
    );
    //Should I have to add 0.5 to this? I would think not but it looks weird otherwise.
    return value;
}

struct material{
    vec3 col;
    int type;
};

struct SDF{
    float dist;
    material mat;
};

SDF sphereSDF(vec3 p, float r, material mat){
    return SDF(length(p) - r, mat);
}

SDF boxSDF(vec3 p, vec3 s, material mat){
    vec3 q = abs(p) - s;
    return SDF(length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0), mat);
}

SDF infiniteSpherePatternSDF(vec3 p, vec3 c, material mat){
    vec3 q = mod(p + 0.5*c, c) - 0.5*c;
    return sphereSDF(q, 0.25, mat);
}

SDF infiniteBoxPatternSDF(vec3 p, vec3 c, material mat){
    vec3 q = mod(p + 0.5*c, c) - 0.5*c;
    return boxSDF(q, vec3(0.25), mat);
}

SDF yPlaneSDF(vec3 p, float y, material mat){
    return SDF(p.y - y, mat);
}

SDF cylinderSDF(vec3 p, float h, float r, material mat){
  vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
  return SDF(min(max(d.x, d.y), 0.0) + length(max(d, 0.0)), mat);
}

SDF finiteCylinderPatternSDF(in vec3 p, in float c, in vec3 l, material mat){
    vec3 q = p - c*clamp(round(p/c), -l, l);
    return cylinderSDF(q, 2.0, 0.4, mat);
}

//https://www.shadertoy.com/view/Nld3DB
SDF triPrismSDF(vec3 p, vec3 s, material mat){
    p.x = abs(p.x);
    p.xy -= vec2(s.x, -s.y);
    vec2 e = vec2(-s.x, s.y*2.0);
    vec2 se = p.xy - e*clamp(dot(p.xy, e)/dot(e, e), 0.0, 1.0);
    float d1 = length(se);
    if(max(se.x, se.y) < 0.0){
        d1 = -min(d1, p.y);
    }
    float d2 = abs(p.z) - s.z;
    return SDF(length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.0), mat);
}

SDF sceneSDF(vec3 p){
    float xr = 0.0;
    float yr = time*0.3 + (3.1415926535/4.0)*1.0;
    
    float sxr = sin(xr);
    float syr = sin(yr);
    float cxr = cos(xr);
    float cyr = cos(yr);
    
    mat3 xRot;
    xRot[0] = vec3(1, 0, 0);
    xRot[1] = vec3(0, cxr, -sxr);
    xRot[2] = vec3(0, sxr, cxr);
    
    mat3 yRot;
    yRot[0] = vec3(cyr, 0, -syr);
    yRot[1] = vec3(0, 1, 0);
    yRot[2] = vec3(syr, 0, cyr);
    
    //SDF ground = yPlaneSDF(p, -1.5, material(vec3(1), 1));
    //ground.dist -= perlinNoise((p - vec3(0, 0, 10))*yRot)*0.15;
    //SDF s1 = infiniteSpherePatternSDF(p - vec3(0), vec3(2, 0, 2), material(vec3(1), 0));
    //SDF s1 = sphereSDF(p - vec3(sin(time*0.5)*3.0, 0, cos(time*0.5)*3.0 + 5.0), 0.25, material(vec3(1), 0));
    //SDF b1 = infiniteBoxPatternSDF((p - vec3(0, 0, 0))*xRot*yRot, vec3(2), material(vec3(0, 1, 0), 0));
    //SDF b1 = boxSDF((p - vec3(0, 0, 5))*yRot*xRot, vec3(0.5, 2, 0.5), material(vec3(0, 0, 0.5), 0));
    SDF pillars = finiteCylinderPatternSDF((p - vec3(0, 0, 10))*yRot, 2.0, vec3(2, 0, 2), material(vec3(0.6), 0));
    SDF base1 = boxSDF((p - vec3(0, -1.0, 10))*yRot, vec3(4.5, 0.25, 4.5), material(vec3(0.6), 0));
    SDF base2 = boxSDF((p - vec3(0, -1.55, 10))*yRot, vec3(5, 0.5, 5), material(vec3(0.6), 0));
    SDF roof1 = boxSDF((p - vec3(0, 2.0, 10))*yRot, vec3(4.75, 0.25, 4.75), material(vec3(0.6), 0));
    SDF roof2 = triPrismSDF((p - vec3(0, 3.25, 10))*yRot, vec3(4.75, 1.0, 4.75), material(vec3(0.6), 0));
    SDF inter = boxSDF((p - vec3(0, 0, 10))*yRot, vec3(4.4, 2.0, 2.75), material(vec3(0.6), 0));
    float closest = min(/*ground.dist, min(*/pillars.dist, min(base1.dist, min(base2.dist, min(roof1.dist, min(roof2.dist, inter.dist)))))/*)*/;
    if(closest == base1.dist){
        return base1;
    }else if(closest == base2.dist){
        return base2;
    }else if(closest == pillars.dist){
        return pillars;
    }else if(closest == roof1.dist){
        return roof1;
    }else if(closest == roof2.dist){
        return roof2;
    }else/* if(closest == inter.dist)*/{
        return inter;
    }/*else{
        return ground;
    }*/
    //return b1;
}

bool raymarch(vec3 o, vec3 d, out float t, out material mat, int ms, float eps){
    t = 0.0;
    for(int i = 0; i < ms && t < 30.0; i++){
        SDF s = sceneSDF(o + d*t);
        t += s.dist;
        if(s.dist < eps && t >= 0.0){
            //Gets rid of some strange artifacts
            t -= s.dist;
            
            mat = s.mat;
            return true;
        }
    }
    return false;
}

vec3 getNormal(vec3 h){
    return normalize(vec3(
        sceneSDF(vec3(h.x + 0.01, h.yz)).dist - sceneSDF(vec3(h.x - 0.01, h.yz)).dist,
        sceneSDF(vec3(h.x, h.y + 0.01, h.z)).dist - sceneSDF(vec3(h.x, h.y - 0.01, h.z)).dist,
        sceneSDF(vec3(h.xy, h.z + 0.01)).dist - sceneSDF(vec3(h.xy, h.z - 0.01)).dist
    ));
}

float getLighting(vec3 h, vec3 lpos){
    vec3 n = getNormal(h);
    vec3 lRay = normalize(lpos - h);
    float c = dot(n, lRay);
    float lt;
    material mat;
    bool rl = raymarch(h + n*0.01, lRay, lt, mat, 30, 0.001);

    if(rl){
        c -= 0.4;
    }else{
        c = dot(n, lRay);
    }
    return c;
}

vec3 reflectRay(vec3 h, vec3 d){
    vec3 n = getNormal(h);
    return d - 2.0*n*dot(n, d);
}

void main(void) {
    vec3 col = vec3(0);
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    vec3 lPos = vec3(10, 10, -10.0 + time*0.0);
    vec3 o = vec3(0, 0.6, time*0.0 - 3.0);
    vec3 d = normalize(vec3(uv, 1));
    //https://www.shadertoy.com/view/XslGWn{
    bool red = mod(gl_FragCoord.xy.x, 2.0) > 0.5;
    mod(gl_FragCoord.xy.y, 2.0) > 0.5 ? red = !red : red = red;
    //}
    
    if(delag){
        if(red){
            float tl;
            material matl;
            vec3 ol = o - vec3(eyeDist/2.0, 0, 0);
            bool rl = raymarch(ol, d, tl, matl, 100, 0.01);

            if(rl){
                float cl = getLighting(ol + d*tl, lPos);
                if(matl.type != 1){
                    float rtl;
                    material rmatl;
                    bool rrl = raymarch(ol + d*tl + getNormal(ol + d*tl)*0.01, normalize(reflectRay(ol + d*tl, d)), rtl, rmatl, 30, 0.01);
                    if(rrl){
                        float rcl = getLighting(ol + d*tl + getNormal(ol + d*tl)*0.01 + normalize(reflectRay(ol + d*tl, d))*rtl, lPos);
                        col.r += mix(
                            mix(matl.col.r, rmatl.col.r*max(rcl, 0.1), reflectiveness)*max(cl, 0.1),
                            fogColor.r,
                            min(tl/20.0, 1.0)
                        );
                    }else{
                        col.r += mix(
                            mix(matl.col.r, 1.0, reflectiveness)*max(cl, 0.1),
                            fogColor.r,
                            min(tl/20.0, 1.0)
                        );
                    }
                }else{
                    col.r += mix(matl.col.r*max(cl, 0.1), fogColor.r, min(tl/20.0, 1.0));
                }
            }else{
                col.r = fogColor.r;
            }
        }else{
            float tr;
            material matr;
            vec3 or = o + vec3(eyeDist/2.0, 0, 0);
            bool rr = raymarch(or, d, tr, matr, 100, 0.01);

            if(rr){
                float cr = getLighting(or + d*tr, lPos);
                if(matr.type != 1){
                    float rtr;
                    material rmatr;
                    bool rrr = raymarch(or + d*tr + getNormal(or + d*tr)*0.01, normalize(reflectRay(or + d*tr, d)), rtr, rmatr, 30, 0.01);
                    if(rrr){
                        float rcr = getLighting(or + d*tr + getNormal(or + d*tr)*0.01 + normalize(reflectRay(or + d*tr, d))*rtr, lPos);
                        col.gb += mix(
                            mix(matr.col.gb, rmatr.col.gb*max(rcr, 0.1), reflectiveness)*max(cr, 0.1),
                            fogColor.gb,
                            min(tr/20.0, 1.0)
                        );
                    }else{
                        col.gb += mix(
                            mix(matr.col.gb, fogColor.gb, reflectiveness)*max(cr, 0.1),
                            fogColor.gb,
                            min(tr/20.0, 1.0)
                        );
                    }
                }else{
                    col.gb += mix(matr.col.gb*max(cr, 0.1), fogColor.gb, min(tr/20.0, 1.0));
                }
            }else{
                col.gb = fogColor.gb;
            }
        }
    }else{
        float tl;
        material matl;
        vec3 ol = o - vec3(eyeDist/2.0, 0, 0);
        bool rl = raymarch(ol, d, tl, matl, 100, 0.01);
        
        if(rl){
            float cl = getLighting(ol + d*tl, lPos);
            if(matl.type != 1){
                float rtl;
                material rmatl;
                bool rrl = raymarch(ol + d*tl + getNormal(ol + d*tl)*0.01, normalize(reflectRay(ol + d*tl, d)), rtl, rmatl, 50, 0.01);
                if(rrl){
                    float rcl = getLighting(ol + d*tl + getNormal(ol + d*tl)*0.01 + normalize(reflectRay(ol + d*tl, d))*rtl, lPos);
                    col.r += mix(
                        mix(matl.col.r, rmatl.col.r*max(rcl, 0.1), reflectiveness)*max(cl, 0.1),
                        fogColor.r,
                        min(tl/20.0, 1.0)
                    );
                }else{
                    col.r += mix(
                        mix(matl.col.r, fogColor.r, reflectiveness)*max(cl, 0.1),
                        fogColor.r,
                        min(tl/20.0, 1.0)
                    );
                }
            }else{
                col.r += mix(matl.col.r*max(cl, 0.1), fogColor.r, min(tl/20.0, 1.0));
            }
        }else{
            col.r = fogColor.r;
        }

        float tr;
        material matr;
        vec3 or = o + vec3(eyeDist/2.0, 0, 0);
        bool rr = raymarch(or, d, tr, matr, 100, 0.01);

        if(rr){
            float cr = getLighting(or + d*tr, lPos);
            if(matr.type != 1){
                float rtr;
                material rmatr;
                bool rrr = raymarch(or + d*tr + getNormal(or + d*tr)*0.01, normalize(reflectRay(or + d*tr, d)), rtr, rmatr, 50, 0.01);
                if(rrr){
                    float rcr = getLighting(or + d*tr + getNormal(or + d*tr)*0.01 + normalize(reflectRay(or + d*tr, d))*rtr, lPos);
                    col.gb += mix(
                        mix(matr.col.gb, rmatr.col.gb*max(rcr, 0.1), reflectiveness)*max(cr, 0.1),
                        fogColor.gb,
                        min(tr/20.0, 1.0)
                    );
                }else{
                    col.gb += mix(
                        mix(matr.col.gb, fogColor.gb, reflectiveness)*max(cr, 0.1),
                        fogColor.gb,
                        min(tr/20.0, 1.0)
                    );
                }
            }else{
                col.gb += mix(matr.col.gb*max(cr, 0.1), fogColor.gb, min(tr/20.0, 1.0));
            }
        }else{
            col.gb = fogColor.gb;
        }
    }
    glFragColor = vec4(pow(col, vec3(1.0/2.2)), 1);
}
