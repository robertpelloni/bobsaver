#version 420

// original https://www.shadertoy.com/view/wtSfWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: sukupaperu
// Title: Astral Train
// Music: "Gazela" by Teetow - https://soundcloud.com/teetow/gazela
// Big thanks to Teetow for this special edit : https://soundcloud.com/teetow/gazela-astral-train-edit

#define P 6.283185307

// global variables
int wagonId = -1, railsId = -1;
vec3 mapTravel, mapGlobal;
float t, isMagicalWorld;

// other functions
float rand(in vec2 st){ return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.585); }
float cord(in float x, in float h, in float d) { x = abs(x) - d*.5; return (x*x)*h - (d*d*.25)*h; }
float anim1(float x, float sm){ float xmd = mod(x,2.) - .5; return smoothstep(-sm,sm,xmd) - smoothstep(-sm,sm,xmd - 1.); }

// color functions
vec3 SpectrumPoly(in float x) {
    // https://www.shadertoy.com/view/wlSBzD
    return (vec3( 1.220023e0,-1.933277e0, 1.623776e0)+(vec3(-2.965000e1, 6.806567e1,-3.606269e1)+(vec3( 5.451365e2,-7.921759e2, 6.966892e2)+(vec3(-4.121053e3, 4.432167e3,-4.463157e3)+(vec3( 1.501655e4,-1.264621e4, 1.375260e4)+(vec3(-2.904744e4, 1.969591e4,-2.330431e4)+(vec3( 3.068214e4,-1.698411e4, 2.229810e4)+(vec3(-1.675434e4, 7.594470e3,-1.131826e4)+ vec3( 3.707437e3,-1.366175e3, 2.372779e3)*x)*x)*x)*x)*x)*x)*x)*x)*x;
}
vec3 hsv2rgb(in vec3 c) { vec3 rgb = clamp(abs(mod(c.x*6.0 + vec3(0.0,4.0,2.0),6.0) - 3.0) - 1.0,0.0,1.0); return c.z*mix(vec3(1.0),rgb,c.y); }

// coordinate transformation functions
vec2 fold(vec2 p, float a){ vec2 n = vec2(cos(-a),sin(-a)); return p - 2.*min(0.,dot(p,n))*n; }
mat2 rot(in float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

// 3d sdf functions
float box(in vec3 p, in vec3 s, in float r) { return length(max(abs(p) - s,0.)) - r; }
float rcyl(in vec3 p, in float ra, in float rb, in float h) { vec2 d = vec2(length(p.xz) - 2.*ra+rb, abs(p.y) - h); return min(max(d.x,d.y),0.) + length(max(d,0.)) - rb; }
float cyl(in vec3 p, in float h, in float r) { vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r); return max(length(max(abs(p.y) - h,0.)) - .01, length(p.xz) - r) - .01;}

float wagon(in vec3 p, in float hadPanto) {
    vec3 cabineS = vec3(2.5,.66,.5);
    vec3 cabineP = p+ vec3(0.,cos(t*40.)*.002,0.);// + vec3(0.,cos(t*40.)*.00,0.)
    float cabine = max(box(cabineP, cabineS, .07), -cabineP.y - .32);
    float cabineInner = -max(box(cabineP, cabineS*0.95, .07),-p.y - .3);
    
    float window = -min(
        box(vec3(mod(cabineP.x,.628) - .314,cabineP.yz) - vec3(0.,.275,0.), vec3(.2,.15,1.), .03),
        box(cabineP.zyx - vec3(0.,.275,0.), vec3(.2,.15,3.), .03)
    );
    cabine = max(cabine, window);
    
    float cabinePart2 = max(rcyl(cabineP.yxz,.45,.07,2.5), -cabineP.y + .69);
    cabinePart2 = min(cabinePart2, max(box(cabineP, cabineS, .085), abs(cabineP.y) - .02));
    
    vec3 wheelsP = vec3(p.y + .525,abs(p.z) - .35,abs(abs(p.x) - 2.) - .25);
    float wheels = max(cyl(wheelsP, 0.05, .15),-cyl(wheelsP - vec3(0.,0.1,0.), 0.06, .13));
    wheels = min(wheels,box(wheelsP - vec3(.1,.1,.0),vec3(.08,.04,.25),.001));
    wheels = min(wheels,cyl(wheelsP + vec3(0.,.05,0.), -0.002, .175));
    vec3 attachesP = wheelsP.yzx - vec3(0.,0.,0.1);
    float attaches = min(cyl(attachesP,.5,.04),cyl(attachesP - vec3(0.,.5,0.),.001,.08));
    attaches = min(attaches,box(p + vec3(0.,.4,0.), vec3(1.35,0.075,0.45), 0.05));
    wheels = min(wheels,attaches);
    
    vec3 pantoP = p + vec3(0.,-.92,0.);
    float panto = box(pantoP,vec3(.2,.05,.2),.01);
    vec3 pantoArmP = vec3(abs(pantoP.x) - .15,abs(pantoP.y - .22) - .1,abs(pantoP.z) - .1);
    vec3 pantoArm2P = vec3(abs(pantoP.x) - .05,pantoP.y - .4125,pantoP.z);
    pantoArmP.xy *= rot(-P*.1);
    panto = min(panto,box(pantoArmP,vec3(.17,.001,.001),.01));
    panto = min(panto,max(max(max(box(pantoArm2P,vec3(.5,.01,.2),.02),abs(pantoArm2P.x) -.03),-box(pantoArm2P + vec3(0.,0.01,0.),vec3(.5,.01,.2),.02)),-pantoArm2P.y + .008));
    
    wheels = min(wheels,mix(panto,10e9,hadPanto));
    
    float d = min(min(cabine,wheels),cabinePart2);
    d = max(d, cabineInner);
    
    wagonId = d == window ? 2
        : d == cabineInner ? 4
        : d == cabine ? 1
        : d == wheels ? 2
        : 3
    ;
    return d;
}

float rails(in vec3 p) {
    vec3 railsP = vec3(0.,p.y,abs(p.z) - .37) + vec3(0.,0.745,0.);
    float rails = min(box(railsP,vec3(.1,.04,.02),.01),box(vec3(railsP.x,abs(railsP.y) - .04,railsP.z),vec3(.1,.01,.04),.005));
    float traverses = box(vec3(mod(p.x,.5) - .25,p.y + .846,p.z),vec3(.08,.04,.5),.001);
    
    float sol = (p.y + mix(.86,10e2,isMagicalWorld));
    
    float piloneEcart = 15.;
    vec3 pilonesP = vec3(mod(p.x,piloneEcart) - piloneEcart*.5,p.yz) - vec3(0.,0.5,.8);
    float pilones = box(vec3(abs(pilonesP.x) - .05,pilonesP.y,abs(pilonesP.z) - .05),vec3(.0015,1.5,.0015),.01);
    vec3 pilonesMeshP = vec3(pilonesP.x,abs(mod(pilonesP.y,.25) - .125) - .06,pilonesP.z);
    vec3 pilonesMeshP2 = pilonesMeshP.zyx;
        pilonesMeshP.x = pilonesMeshP.x*sign(pilonesMeshP.z); pilonesMeshP2.x = pilonesMeshP2.x*sign(pilonesMeshP2.z);
        pilonesMeshP.xy *= rot(P*.15); pilonesMeshP2.xy *= rot(P*.15);
        pilonesMeshP.z = abs(pilonesMeshP.z) - .05; pilonesMeshP2.z = abs(pilonesMeshP2.z) - .05;
    pilones = min(pilones,max(
        min(box(pilonesMeshP,vec3(.15,.002,.002),.001),box(pilonesMeshP2,vec3(.15,.002,.002),.001)),
        abs(-pilonesP.y) - 1.5)
    );
    vec3 catP = pilonesP + vec3(0.,-1.2,.8);
    vec3 cat2P = catP + vec3(0.,0.3,-.28);
    catP.yz = fold(catP.yz,-.25); catP.z -= .25;
    pilones = min(pilones,box(catP,vec3(.001,.001,.6),.005));
    pilones = min(pilones,cyl(vec3(catP.y,abs(catP.z - .45) - .02,catP.x),-.01,.02));
    pilones = min(pilones,box(cat2P,vec3(.001,.001,.26),.005));
    pilones = min(pilones,box(cat2P + vec3(0.,0.025,0.25),vec3(piloneEcart,0.001,0.001),.005));
    float cableCurve = cord(pilonesP.x, 0.002, piloneEcart);
    pilones = min(pilones,box(cat2P + vec3(0.,-.25 - cableCurve,0.25),vec3(piloneEcart,0.001,0.001),.001));
    float vertPos = .125 + cableCurve*.4;
    pilones = min(pilones,box(vec3(mod(cat2P.x,1.) - .5,cat2P.y - vertPos*.5 - .02,cat2P.z + .25),vec3(.0,vertPos,.0),.005));
    rails = min(rails,pilones);
    
    float d = min(min(rails,traverses),sol);
    railsId = d == rails ? 1 : d == traverses ? 2 : 3;
    return d;
}

// function for hills heightmap
float deniv(in vec2 p) {
    vec2 pp;
    p *= rot(P*.125);
    return cos(p.x*.1)*1.2 + sin(pp.x*.81)*.05 + cos(p.y*0.2);
}

// main sdf function
float df(in vec3 p) {
    p.yz *= rot(P*-0.030);
    p.xz *= rot(P*0.418);
    p = p.zyx;
    p.x -= t*10.;
    mapGlobal = p;
    p.yz *= rot((P*.125 + P*cos(p.x*.025))*isMagicalWorld);
    
    float aaaa= p.y;
    float dBtwWagons = 5.56, dBtwWagonsH = dBtwWagons*.5;
    float tSpeed = t*15. + cos(t*.55)*10.;
    
    float pxWagon = p.x + tSpeed;
    float wagonNo = floor(pxWagon/dBtwWagons);
    float pxDeniv = wagonNo*dBtwWagons + dBtwWagonsH - tSpeed;
    vec3 wagonP = vec3(mod(pxWagon,dBtwWagons) - dBtwWagonsH,p.y + deniv(vec2(pxDeniv,p.z)),p.z);
    
    float pyWshifted = deniv(vec2(pxDeniv - dBtwWagonsH,p.z)) - deniv(vec2(pxDeniv + dBtwWagonsH,p.z));
    wagonP.xy *= rot(atan(pyWshifted/dBtwWagons));
    
    p.y += deniv(p.xz);
    
    float wagon = wagon(wagonP,mod(wagonNo,3.));
    float rails = rails(p);
    
    float d = min(rails,wagon);
    
    if(d == wagon) railsId = 0;
    mapTravel = vec3(pxWagon,wagonP.yz);
    return d;
}

vec3 normal(in vec3 p) { float d = df(p); vec2 u = vec2(0.,mix(.001,.1,isMagicalWorld)); return normalize(vec3(df(p + u.yxx),df(p + u.xyx),df(p + u.xxy)) - d); }

// raymarching loop
#define MAX_D 150.
#define LIM .001
#define MAX_IT 80
struct rmRes { vec3 pos; int it; bool hit; };
rmRes rm(in vec3 c, in vec3 r) {
    vec3 p = c;
    int it;
    bool hit = false;
    for(int i = 0; i < MAX_IT; i++) {
        float d = df(p);
        if(d < LIM) { hit = true; break; }
        if(distance(c,p) > MAX_D) break;
        p += d*r;
        it = i;
    }
    rmRes res; res.pos = p; res.it = it; res.hit = hit;
    return res;
}

// 2d (cheap) starfield functions
float sq(in vec2 st, in vec2 s) { return length(max(abs(st) - s, 0.)) - .001; }
float star1(in vec2 st) { return max(abs(st.x)*abs(st.y) - .001,length(abs(st)) - .5); }
float star2(in vec2 st) { return length(max(abs(st.y) + .02,0.)*max(abs(st.x) + .02,0.)) - .01; }
float star3(in vec2 st) { return abs(length(st) - .4) - .03; }
float star4(in vec2 st) { return min(sq(st,vec2(.5,.05)),sq(st,vec2(.05,.5))); }
float star5(in vec2 st) { return abs(st.x) + abs(st.y) - .125; }
float starSel(in vec2 st, in float sel) { st.x -= sel; return max(min(star1(st),min(star2(st + vec2(1.,0.)),min(star3(st + vec2(2.,0.)),min(star4(st + vec2(3.,0.)),star5(st + vec2(4.,0.)))))),(length(vec2(st.x + sel,st.y)) - .5)); }
vec3 starField(in vec2 st) {
    st *= 80.;
    float d = starSel((fract(st) - .5)*1.5,floor(rand(floor(st))*100.));
    return mix(vec3(1.),vec3(0.122,0.056,0.305),step(0.02,d));
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy - .5;
    st.x *= resolution.x/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy - .5;
    t = mod(time,240.)*-1.;
    
    isMagicalWorld = anim1(t*.025 + (st.x + .5)*.015,.1);
    
    vec3 c = vec3(2.,1.,-5.);
    vec3 r = normalize(vec3(st,.65));
    r.xz *= rot(.5*(m.x));
    r.yz *= rot(.5*(m.y));
    rmRes res = rm(c,r);
    
    vec3 skyColor = mix(vec3(.529,.807,.98),vec3(6.),isMagicalWorld);
    vec2 bgMapPos = vec2(atan(r.x,r.z),r.y);
    vec3 color = mix(skyColor,starField(bgMapPos + .015*t),isMagicalWorld);
    color = mix(vec3(0.980,0.724,0.969)*1.2,color,clamp(bgMapPos.y*2.2 + 1.5,0.,1.));
    
    if(res.hit) {
        vec3 n = normal(res.pos);
        vec3 l = normalize(vec3(-0.387,0.666,0.087));
        
        float wagonColSel = mod(floor(mapTravel.x/5.56),5.)/5.;
        color = wagonId == 1 ? hsv2rgb(vec3(.3 + wagonColSel,.8,1.))
            : wagonId == 2 ? vec3(.2)
            : wagonId == 4 ? vec3(0.109,0.271,0.500)
            : wagonId == 3 ? vec3(.95)
            : color;
        color = railsId == 1 ? vec3(.5)
            : railsId == 2 ? vec3(0.635,0.324,0.169)
            : railsId == 3 ? vec3(0.498,.9,0.1)
            : color;
        
        rmRes resShadow = rm(res.pos - r*.004,l);
        if(resShadow.hit) color = mix(color*clamp(step(.4,-skyColor),0.4,1.),color,isMagicalWorld);
        
        color = mix(color,SpectrumPoly(clamp(.5+.5*cos(dot(n,-r)*8. + t),0.,1.)),isMagicalWorld);
        skyColor = SpectrumPoly(fract(mapGlobal.x*.015))*mix(3.,30.,isMagicalWorld);
        color += distance(res.pos,c)*.025;
    }
    color += pow(float(res.it)/float(MAX_IT),2.)*skyColor;

    glFragColor = vec4(color - pow(length(st)*.75,2.),1.0);
}
