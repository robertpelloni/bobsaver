#version 420

// original https://www.shadertoy.com/view/Wt2yzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float GaborNoise(vec3 p, float z, float k) {
    // https://www.shadertoy.com/view/wsBfzK
    float d=0.,s=1.,m=0., a;
    for(float i=0.; i<5.; i++) {
        vec3 q = p*s, g=fract(floor(q)*vec3(123.34,233.53,314.15));
        g += dot(g, g+23.234);
        a = fract(g.x*g.y)*1e3 +z*(mod(g.x+g.y, 2.)-1.); // add vorticity
        q = (fract(q)-.5);
        //random rotation in 3d. the +.1 is to fix the rare case that g == vec3(0)
        //https://suricrasia.online/demoscene/functions/#rndrot
        q = erot(q, normalize(tan(g+.1)), a);
        d += sin(q.x*10.+z)*smoothstep(.25, .0, dot(q,q))/s;
        p = erot(p,normalize(vec3(-1,1,0)),atan(sqrt(2.)))+i; //rotate along the magic angle
        m += 1./s;
        s *= k; 
    }
    return d/m;
}

float super(vec3 p) {
    return sqrt(length(p*p));
}

float super(vec2 p) {
    return sqrt(length(p*p));
}

float box(vec3 p, vec3 d) {
    vec3 q = abs(p)-d;
    return super(max(q,0.))+min(0.,max(q.x,max(q.y,q.z)));
}

float box(vec2 p, vec2 d, float es) {
    vec2 q = abs(p)-d;
    vec2 qq = max(q,0.);
    return mix(super(qq),length(qq),es) +min(0.,max(q.x,q.y));
}

vec3 distorted_p;
float plate;
float bx;
float bump;
float scene(vec3 p) {
    float plateangle = atan(p.x,p.y);
    
    //different noise for each dimension
    vec3 distort = vec3(0);
    distort.x += GaborNoise(p/2., time*3., 1.15)*.3;
    distort.y += GaborNoise(p/2.+10., time*3., 1.15)*.3;
    distort.z += GaborNoise(p/2.+20., time*3., 1.15)*.3;

    float es = smoothstep(0.,.3,GaborNoise(p*2., 0., 1.15));
    plate = box(vec2(p.z+1.6,length(p.xy)), vec2(0.1,2.5+sin(plateangle*23.)*.004 -abs(es)*.001 ), es*.8+.2 )-.07;
    plate = min(plate, box(vec2(p.z+6.6,length(p.xy)),vec2(5.,.8-abs(es)*.001),0. ));

    p += distort;

    distorted_p = p;
    vec3 ap = abs(p);
    bump = min(ap.x,min(ap.y,ap.z));
    bump = smoothstep(0.,.1,bump);
    bx = box(p,vec3(1))-.3-bump*.05;
    return min(bx,plate);
}

vec3 norm(vec3 p) {
    mat3 k = mat3(p,p,p)-mat3(0.001);
    return normalize(scene(p) - vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}

float bayer() {
    return 0.0; //texelFetch(iChannel0, ivec2(gl_FragCoord.xy) % 8, 0).x;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 mouse = (mouse*resolution.xy.xy-0.5*resolution.xy)/resolution.y;

    vec3 cam = normalize(vec3(1.5,uv));
    vec3 init = vec3(-10.,0,-0.5);
    
    float yrot = 0.5;
    float zrot = time*.2;
    //if (mouse*resolution.xy.z > 0.) {
    //    yrot += -4.*mouse.y;
    //    zrot = 4.*mouse.x;
    //}
    cam = erot(cam, vec3(0,1,0), yrot);
    init = erot(init, vec3(0,1,0), yrot);
    cam = erot(cam, vec3(0,0,1), zrot);
    init = erot(init, vec3(0,0,1), zrot);
    
    vec3 p = init;
    bool hit = false;
    float dist;
    for (int i = 0; i < 250 && !hit; i++) {
        dist = scene(p);
        hit = dist*dist < 1e-6;
        p+=dist*cam*.8;
        if (distance(p,init)>50.) break;
    }
    bool pl = dist == plate;
    float lbx = bx;
    float lb = bump;
    vec3 local_coords = distorted_p;
    vec3 n = norm(p);
    vec3 r = reflect(cam,n);
    float ss = smoothstep(-.05,.05,scene(p+vec3(.05)/sqrt(3.)));
    float rao = smoothstep(-.2,.1,scene(p+r*.1)) * smoothstep(-.4,.1,scene(p+n*.1));
    float tex = GaborNoise(local_coords*3., 0., 1.5)+.5;
    float diff = mix(length(asin(sin(n*2.)*.9)*0.5+0.5)/sqrt(3.),ss,.2)+.1;
    float spec1 = length(asin(sin(r*4.)*.9)*0.5+0.5)/sqrt(3.);
    float spec2 = length(asin(sin(r*3.)*.9)*0.5+0.5)/sqrt(3.);
    float specpow = mix(2.,5.,tex);
    float frens = 1.-pow(dot(cam,n),2.)*0.98;

    vec3 col1 = vec3(0.7,0.3,0.4)*diff + pow(spec2,specpow)*frens*.5;
    vec3 col2 = vec3(0.7)*(ss*.8+.2) + pow(spec1*1.1,40.)*frens + spec1*frens*.3;

    float bgdot = length(asin(sin(cam*3.5)*.8)*0.4+0.6)/sqrt(3.);
    vec3 bg = vec3(.2,.2,.3) * bgdot*bgdot + pow(bgdot, 10.)*2.;
    
    float tex2 = smoothstep(0.1,.8,GaborNoise(p*4., 0., 1.2));
    vec3 bounce = p+r*lbx*(2.-tex2);
    float rao2 = smoothstep(-lbx,lbx,scene(bounce));
    vec3 bouncecol = mix(vec3(.7,.3,0.4), vec3(.8), smoothstep(-.8,.8,bounce.x*bounce.y*bounce.z));
    vec3 pedistal = vec3(.1)*spec1 + pow(spec1, 10.-tex2*2.);
    if (n.z>.99) pedistal = mix(bouncecol*frens*.4, pedistal, rao2);
    
    vec3 col = mix(col1,col2,smoothstep(-.05,.05,local_coords.x*local_coords.y*local_coords.z));
    col *= lb*.3+.7;
    if (pl) col = pedistal;
    glFragColor.xyz = hit ? rao*col : bg;
    glFragColor *= 1.- dot(uv,uv)*.9;
    glFragColor = sqrt(glFragColor) + bayer()/128.;
    glFragColor = mix(smoothstep(vec4(0), vec4(1), glFragColor), glFragColor, 0.25);
}
