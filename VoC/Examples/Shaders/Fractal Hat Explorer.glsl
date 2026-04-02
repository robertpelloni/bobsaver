#version 420

// original https://www.shadertoy.com/view/sdSyzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535

vec2 foldRotate16 ( in vec2 p ) {
    const vec2 k1 = vec2(0.38268343230, -0.9238795325 );
    const vec2 k2 = vec2(0.19509032201, -0.9807852804 );
    p = abs(p);
    p = (p.y<p.x) ? p : p.yx;
    p -= min(2.0*dot(k1,p),0.0)*k1;
    p -= min(2.0*dot(k2,p),0.0)*k2;
    return p;
}

vec2 getDist(vec3 p) {
    
    // parameters :
    
    int iterations = 6;
    
    vec3 offset = vec3(2.,2.,2.);

    float ang1 = 3.88322207745;
    float ang2 = mouse.x*resolution.xy.x/resolution.x*PI;
    float ang3 = mouse.y*resolution.xy.y/resolution.y*PI;    
    
    //
    
    float size = 1.;
    
    float t = p.y + 3.25;    
    float orbitTrap = 0.;

    mat3 rot = mat3(cos(ang1),-sin(ang1),0.,  sin(ang1),cos(ang1),0.,  0.,0.,1.)
              *mat3(cos(ang2),0.,sin(ang2),  0.,1.,0.,  -sin(ang2),0.,cos(ang2))
              *mat3(1.,0.,0.,  0.,cos(ang3),sin(ang3),  0.,-sin(ang3),cos(ang3));

            
    for( int i=0; i++<iterations; ){
        
        p.xz = foldRotate16(p.xz);
        //p.xy = foldRotate16(p.xy);

        size *= 0.5;
        
        p = abs(p.zxy*rot) - offset*size;

        orbitTrap += dot(p,p);
    }
    
    float t2 = length(p) - size*2.;
    
    if (t<t2) { return vec2(t,-1.); }

    return vec2(t2,0.5-cos(orbitTrap*0.8)*0.5);
}

float rayMarch( vec3 ro, vec3 rd) {

    float coneWidth = 0.001;
    float t = 0.;
    int i = 0;

    while ( i<100 && t<999. ) {

        float r = abs( getDist( ro + rd*t ).x );

        if ( r <= coneWidth*t ) break;
        t += r;
        i ++;
    }
    
    return t;
}

vec3 distance_field_normal(vec3 pos) {
    vec2 eps = vec2(0.0001,0.0);
    float nx = getDist(pos + eps.xyy).x;
    float ny = getDist(pos + eps.yxy).x;
    float nz = getDist(pos + eps.yyx).x;
    return normalize(vec3(nx, ny, nz)-getDist(pos).x);
}

//ambient occlusion
//https://www.shadertoy.com/view/MtlBWB
const vec3 sq = 1./vec3(sqrt(2.),sqrt(3.),sqrt(4.));
const float eps = 0.1;
const vec3 eps2 = eps*vec3(2.,3.,4.);
float ao(vec3 p, vec3 n) {
    
    float c1 = float(abs(n.x) < abs(n.y) && abs(n.x) < abs(n.z));
    float c2 = float(abs(n.y) < abs(n.z));
    float c3 = c2 - c2*c1;
    
    vec3 t = vec3(c1, c3, 1. - c1 - c3);
    vec3 u = cross(n, t);
    vec3 v = cross(n, u);    
    
    vec3 epn = eps2[2]*n + p;
    
    float occ  = max(getDist(p + eps*n).x,0.0);
          occ += max(getDist(p + eps*u).x,0.0);
          occ += max(getDist(p - eps*u).x,0.0);
          occ += max(getDist(p + eps*v).x,0.0);
          occ += max(getDist(p - eps*v).x,0.0);
    
    occ += (max(getDist(epn + eps2[2]*u).x,0.0)
        +   max(getDist(epn - eps2[2]*u).x,0.0)
        +   max(getDist(epn + eps2[2]*v).x,0.0)
        +   max(getDist(epn - eps2[2]*v).x,0.0))*0.5;

    occ += max(getDist(p + eps2[0]*n).x*sq[0],0.0);
    occ += max(getDist(p + eps2[1]*n).x*sq[1],0.0);
    occ += max(getDist(epn          ).x*sq[2],0.0);

    return max(1.0 - 1./(1.+2.*occ), 0.0);
}

void main(void) {
    
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy) / resolution.y;
    
    float time2 = time*0.25;
   
    vec3 ro = vec3(cos(-time2)*8., 2.5, sin(-time2)*8. );
    vec3 rd = normalize( vec3(p,-2.0) );
    rd.yz *= mat2(cos(0.3),sin(0.3),-sin(0.3),cos(0.3));
    rd.xz = rd.xz*mat2(sin(time2),cos(time2),cos(time2),-sin(time2));
    
    ////
            
    float dist = rayMarch( ro, rd );
    
    vec3 hit = ro + rd*dist;
    float orbitTrap = getDist(hit).y;
    vec3 normals = distance_field_normal(hit);
    vec3 pos = ro + dist*rd ;

    vec3 col = vec3(.8,.8,1.);
    if ( orbitTrap > 0. ) { col = mix(vec3(0.1,0.15,1.),vec3(1.,0.35,0.3),orbitTrap); }
    
    float diffuse = mix(normals.y,1.,0.65);
    vec3 reflectDir = reflect(-vec3(0.,1.,0.),-normals);
    float specular = pow (max (dot (-rd, reflectDir), 0.0), 100.0);
    float ao = ao(pos, normals);
        
    glFragColor = vec4( sqrt(( col + specular ) * diffuse * ao), 1.0 );

}
