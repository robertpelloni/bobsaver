#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wlyXDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAILLE_GRILLE 500U

#define DISTANCE_DE_VISIBILITE 400.0

#define PROBA_PRESENCE_CUBE 0.05

float hash1( uint n ) 
{
    // integer hash copied from Hugo Elias
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

vec3 rotateX(vec3 p, float a)
{
    float sa = sin(a);
    float ca = cos(a);
    vec3 r;
    r.x = p.x;
    r.y = ca*p.y - sa*p.z;
    r.z = sa*p.y + ca*p.z;
    return r;
}

vec3 rotateY(vec3 p, float a)
{
    float sa = sin(a);
    float ca = cos(a);
    vec3 r;
    r.x = ca*p.x + sa*p.z;
    r.y = p.y;
    r.z = -sa*p.x + ca*p.z;
    return r;
}

vec4 Cellule(uvec3 coord) {
    vec4 h = vec4(hash1(4U*coord.x + 4U*TAILLE_GRILLE*coord.y + 4U*TAILLE_GRILLE*TAILLE_GRILLE*coord.z)
                 ,hash1(1U + 4U*coord.x + 4U*TAILLE_GRILLE*coord.y + 4U*TAILLE_GRILLE*TAILLE_GRILLE*coord.z)
                 ,hash1(2U + 4U*coord.x + 4U*TAILLE_GRILLE*coord.y + 4U*TAILLE_GRILLE*TAILLE_GRILLE*coord.z)
                 ,hash1(3U + 4U*coord.x + 4U*TAILLE_GRILLE*coord.y + 4U*TAILLE_GRILLE*TAILLE_GRILLE*coord.z));
    h.w = step(clamp(1.-PROBA_PRESENCE_CUBE,0.,1.),h.w);
    return h;
}

vec4 RayMarch(vec3 ro, vec3 rd, vec3 cnum, out uvec3 voxel) {
    vec3 p = ro;
    
    vec3 end = cnum / 2.;
    vec3 beg = -end;
    
    float p1, p2, p3;
    float dO;
    
    int i;
    
    if(!(p.x > beg.x && p.x < end.x && p.y > beg.y && p.y < end.y && p.z > beg.z && p.z < end.z)) {
        
        if(rd.x > 0.) p1 = (beg.x - p.x) / rd.x;
        else p1 = (end.x - p.x) / rd.x;
    
        if(rd.y > 0.) p2 = (beg.y - p.y) / rd.y;
        else p2 = (end.y - p.y) / rd.y;

        if(rd.z > 0.) p3 = (beg.z - p.z) / rd.z;
        else p3 = (end.z - p.z) / rd.z;
    
        dO = max(max(p1, p2), p3);
        
        p += rd * dO + sign(rd) * vec3(0.001,0.001,0.001);
        
    }
    
    i = 0;
    
    while(p.x > beg.x && p.x < end.x && p.y > beg.y && p.y < end.y && p.z > beg.z && p.z < end.z) {
        uvec3 coord = uvec3(floor(p.x - beg.x), floor(p.y - beg.y), floor(p.z - beg.z));
        if(Cellule(coord).w == 1.)
        {
            vec3 normal = vec3(0.,0.,0.);
            if(dO == p1) normal.x = -sign(rd.x);
            if(dO == p2) normal.y = -sign(rd.y);
            if(dO == p3) normal.z = -sign(rd.z);

            voxel = coord;
            return vec4(normalize(normal), dO);
        }
        else {
            
            p1 = floor(p.x-beg.x)+beg.x; if(rd.x > 0.) p1++;
            p2 = floor(p.y-beg.y)+beg.y; if(rd.y > 0.) p2++;
            p3 = floor(p.z-beg.z)+beg.z; if(rd.z > 0.) p3++;
            
            p1 = (p1 - ro.x) / rd.x;
            p2 = (p2 - ro.y) / rd.y;
            p3 = (p3 - ro.z) / rd.z;
            
            dO = min(min(p1, p2), p3);
            p = ro + rd * dO + sign(rd) * vec3(0.001,0.001,0.001);
            
        }
        //if(i > 2000) return vec4(0.,0.,0.,-1.);
        i++;
    }
    
    return vec4(0.,0.,0.,0.);
}

float GetLight(vec3 p, vec3 lightPos, vec3 normal) {
    
    vec3 l = normalize(lightPos-p);
    
    float p_sca = dot(normal, l);
    
    return p_sca/2.+0.5;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    vec3 col = vec3(1.,0.,0.);

    vec3 ro = vec3(0, 0, -sqrt(float(TAILLE_GRILLE*TAILLE_GRILLE/4U)+float(TAILLE_GRILLE*TAILLE_GRILLE/4U)+float(TAILLE_GRILLE*TAILLE_GRILLE/4U)));
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));

    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;

    vec2 a = vec2(0.0, 0.0);
    //if (mouse*resolution.xy.x > 0.0) {
        a.x = -(1.0 - mouse.y)*1.5;
        a.y = 4.5 -(mouse.x-0.5)*3.0;
    //}

    rd = rotateX(rd, a.x/1.);
    ro = rotateX(ro, a.x/1.);

    rd = rotateY(rd, a.y/1.);
    ro = rotateY(ro, a.y/1.);

    uvec3 voxel;
    vec4 rm = RayMarch(ro, rd, vec3(TAILLE_GRILLE), voxel);
    vec3 p = ro + rd * rm.w;
    float lum = GetLight(p, ro, rm.xyz);

    col = Cellule(voxel).rgb * lum * (1.-rm.w/DISTANCE_DE_VISIBILITE);

    glFragColor = vec4(col,1.0);
}
