#version 420

// original https://www.shadertoy.com/view/7llBW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float fBox(vec3 p, vec3 s) {
    p = abs(p) - s;
    return max(p.x,max(p.y,p.z));
}

float fTorus(vec3 p, float smallRadius, float largeRadius) {
    return length(vec2(length(p.xz) - largeRadius, p.y)) - smallRadius;
}

mat2 rot(float a) {float s=sin(a), c=cos(a); return mat2(c,s,-s,c);}
float gl1 = 0., gl2 = 0., gl3 = 0., gl4 = 0., gl5 = 0., gl6 = 0., gls1 = 0.;
vec3 map(vec3 p) {
    vec3 r = vec3(999.);
    vec3 b = vec3(999.);

    vec3 q = p;

    p.xz *= rot(-time * .5);
    p.xy *= rot(-time * 2.);
 
    r.x = fTorus(p, .2, 1.);
    vec3 w = p;
    w.xz = abs(w.xz);
    w.xz -= .7;
    r.x = max(r.x,-length(w)+.3);
    r.x = max(r.x,-fTorus(p, .16, 1.));
    
    vec2 u = normalize(p.xz);
    u.x = atan(p.z / p.x);
    u.y = length(p.xz);
    if (sin(u.x * 150.) > 0.) r.z = 6.;
    else {r.z = 3.;gl6 += (.0003/(.0001+pow(r.x+.01, 2.)));}
    
    float rot_speed = time * 8.;
    p.xz *= rot(rot_speed);
    q = p;
    p.xz = abs(p.xz);
    p.xz *= rot(-3.14/4.);
    p.z -= 1.;
    b.x = length(p) - .15;
    if (q.x >= 0. && q.z >= 0.) {b.z = 2.; gl1 += (.01/(.0001+pow(b.x+.008, 2.)));}
    else if (q.x <= 0. && q.z >= 0.) {b.z = 3.; gl2 += (.01/(.0001+pow(b.x+.008, 2.)));}
    else if (q.x <= 0. && q.z <= 0.) {b.z = 4.; gl3 += (.01/(.0001+pow(b.x+.008, 2.)));}
    else {b.z = 5.; gl4 += (.01/(.0001+pow(b.x+.008, 2.)));}
    if (r.x > b.x) r = b; 

    p = q;
    b.x = length(p) - .4;
    gl6 += (.003/(.001+pow(b.x+.008, 2.)));
    b.z = 1.;
    if (r.x > b.x) r = b; 
    
    vec3 m = p;
    p.xz *= rot(3.14/4.);
    q = p; 
    float cur_speed = time * 15.;
    p.xz *= rot(sin(p.z * 15. + cur_speed)*.1);
    p.xz = abs(p.xz);
    
    q.xz *= rot(sin(q.x * 15. + cur_speed)*.1);
    q.xz = abs(q.xz);
    
    b.x = length(q.zy) - .015;
    b.x = min(b.x,length(p.xy) - .015);
    b.x = max(b.x,fBox(p,vec3(1.)));
    gl6 += (.0005/(.0001+pow(b.x+.01, 2.)));
    b.z = 1.;
    if (r.x > b.x) r = b; 
    
    p = m;
    p.y = abs(p.y);
    b.x = length(p) - .75;
    b.x = max(b.x,-length(p)+.65);
    b.x = max(b.x,-fBox(p,vec3(1.,.1,1.)));
    gls1 += (.00001/(.0001+pow(b.x+.01, 2.)));
    b.z = 1.;
    b.y = 1.;
    if (r.x > b.x) r = b; 
    b.y = 0.;
    p = m;
    p.xz *= rot(-rot_speed);
    p = abs(p);
    
    p.xy *= rot(3.14/2.);
    p.zy *= rot(-3.14/3.);

    b.x = fTorus(p, .01, 1.);
    p.zy *= rot(3.14/6.);

    b.x = min(b.x,fTorus(p, .01, 1.));
    b.z = 7.;
    u = normalize(p.xz);
    u.x = atan(p.z / p.x);
    u.y = length(p.xz);
    gl6 += (.001/(.001+pow(b.x+.01, 2.))) * (sin((u.x * 20.+time*50.))*.5+.5);
    
    p = m;
    b.x = max(b.x,-fTorus(p, .16, 1.));
    
    if (r.x > b.x) r = b; 
    
    b.x = length(w) - .3;
    b.x = max(b.x, -length(w) + .25);
    b.x = max(b.x,-fTorus(m, .16, 1.));
    gls1 += (.00001/(.0001+pow(b.x+.01, 2.)));
    b.y = 1.;
    if (r.x > b.x) r = b; 
    
    p = m;
    p.y = abs(p.y);
    p.y -= 1.;
    b.x = length(p) - .15;
    gl6 += (.001/(.001+pow(b.x+.01, 2.))) * (sin((time*50.))*.5+.5);
    b.y = 0.;
    if (r.x > b.x) r = b;     
    
    return r;
}

const vec2 e = vec2(.00035, -.00035);
vec3 norm(vec3 po) {
        return normalize(e.yyx*map(po+e.yyx).x + e.yxy*map(po+e.yxy).x +
                         e.xyy*map(po+e.xyy).x + e.xxx*map(po+e.xxx).x);
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5 ) / resolution.y;
    const float Y = 2.;
    vec3 ro = vec3(0.,Y,-Y),
         rd = normalize(vec3(uv,1.)),
         p, h;
    rd.yz *= rot(-.8);
    float t = 1.;
    for (int i = 0; i < 120; i++) {
        p = ro + rd * t;
        h = map(p);
        if(h.x<.001)
            if(h.y==1.) { h.x = abs(h.x) + .001; }
            else break;
        if(t>40.) break;
        t += h.x;
    }

    vec3 col = vec3(.1);
    
    vec3 ld = vec3(2.);
    ld.xz *= rot(time);
    
    if (h.x < .001) {
        p = ro + rd * t;
        vec3 n = norm(p);
        ld = normalize(ld - p);
    
        if (h.z == 1.) col = vec3(.6, .4, .9);
        
        if (h.z == 2.) col = vec3(.9, .1, .1);
        if (h.z == 3.) col = vec3(.1, .9, .1);
        if (h.z == 4.) col = vec3(.1, .0, .9);
        if (h.z == 5.) col = vec3(.9, .9, .0);
        
        if (h.z == 6.) col = vec3(.72,.45,.2); // copper
        if (h.z == 7.) col = vec3(.7); // steel
    }
    
    col += gl1 * vec3(1.,0.,0.) * .1;
    col += gl2 * vec3(0.,1.,0.) * .1;
    col += gl3 * vec3(0.,0.,1.) * .1;
    col += gl4 * vec3(1.,1.,0.) * .1;
    col += gl5 * vec3(.7,1.,.7) * .1;
    col += gl6 * vec3(.8,.5,1.) * .1;
    
    col += gls1 * vec3(.8,.5,1.) * .1;

    glFragColor = vec4(col,1.0);
}
