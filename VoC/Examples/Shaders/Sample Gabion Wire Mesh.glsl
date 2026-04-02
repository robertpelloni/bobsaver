#version 420

// original https://www.shadertoy.com/view/M3jBD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2024-10-20
// Gabion Wire Mesh ?????
#define PI 3.14159265358979
#define TAU 6.2831853
#define ctrlLevel float(int(mouse*resolution.xy.x/resolution.x*5.+1.)%5)

vec3 gDir;
float A = PI / 4.;// 2.000001 * min(.999999,time * .01); 
float R = 1.;
float r = 1.;
float ratio = 7.;
float level = 1.; 

#define time (time*10.) 
//#define time min(time * 8., 21.3)

#define rot(t) mat2(cos(t), sin(t), -sin(t), cos(t))

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
    return mix(a, b, h) - k*h*(1.0-h);
}

float sdSpring(vec3 p) {
        //
        // A: Incline angle
        // R: Spring radius
        // r: Wire radius
        
        float a = atan(p.z, p.x) / TAU;
        if (a < 0.) a += 1.;
        
        // x1: Unit angle (circumference of the spring's bottom surface)
        // y1: Unit height
        float x1 = 2. * PI * R, y1 = x1 * tan(A), kyx = y1 / x1;
        
        // i0: The total number of unit heights before this point
        float i0 = floor(p.y / y1);
        
        // x: The x-coordinate of point p on the unfolded diagram, and y is the height column
        // (The unfolding is of a cylinder with radius R)
        float x = (i0 + a) * x1, y = p.y;
        
        // p2: The corresponding position of input point p on the unfolded diagram
        // n: Unit vector perpendicular to the spring (straight line) on the unfolded diagram.
        vec2 p2 = vec2(x, y), 
             n = normalize(vec2(-y1, x1));
        
        // Move point p2 into a slanted strip (instead of a square step).
        if (p2.y < p2.x * kyx) p2.x -= x1;
        
        //vec2 fn = vec2(-x1*.5,0);
        ////vec2 n2=abs(n.yx);
        //if (dot(p2-fn,n)<0.)p2 = p2 - 2.* dot(p2-fn,n)*n;    //reflect(p2-fn, n)+fn;
        
        // Find the closest point j1 below p2 on the lower boundary of the strip and the closest point j2 above p2 on the upper boundary.
        float dt1, dt2;
        dt1 = dot(p2 - vec2(0), n);
        vec2 j1 = p2 - dt1 * n;
        dt2 = dot(p2 - vec2(-x1, 0), n);
        vec2 j2 = p2 - dt2 * n; // j2.x += x1;//
        
        // Convert these two intersection points back to their actual 3D coordinates.
        vec3 pj1 = vec3(R * cos(j1.x / R), j1.y, R * sin(j1.x / R));
        vec3 pj2 = vec3(R * cos(j2.x / R), j2.y, R * sin(j2.x / R));
        
        // draw sphere
        float d1 = length(p - pj1) - r;
        float d2 = length(p - pj2) - r;
        return min(d1,d2);
               //d1*max(.01,(length(vec3(p.x,p.y*min(y1/x1,x1/y1),p.z))+.00001)/(length(p)+.000001)*.5);
        //return min(min(d1,d2),R*.5);                  
}

float springAndLine(vec3 p)
{
        
        if(p.y<0.)p.xz=-p.xz,p.xy=-p.xy;
        
        float a = atan(p.z, p.x) / TAU;
        if (a < 0.) a += 1.;                
        float x1 = 2. * PI * R, y1 = x1 * tan(A), kyx = y1 / x1;
        
        
        float cutA = .25 + .5*level;
        vec3 e = vec3(R*cos(TAU*cutA),y1*cutA, R*sin(TAU*cutA));
        vec3 ny = normalize(vec3(0,y1,x1)); 
        
        
        
        ny.xz = rot(TAU*cutA)*ny.xz; // ??        
        vec3 nx = normalize(vec3(e.x,0,e.z));
        vec3 nz = normalize(cross(nx, ny)); // ??
        
        float d1 = (p.y - (e - nz*r*1.1).y); // ??
        float d4 = (p.y - (e - nz*r).y);
        float d2 = -dot(p-e, ny);  // ???
        float d3 = dot(p-e - nz * r*1.05, nz); // ???
        float dms= max(max(d1,d2),d3);
        
        float dline = max(d2, length(vec2(dot(p-e,nx),dot(p-e,nz)))-r); // ???
        
        float dspr = sdSpring(p);
        //float dmx = max(max(dsp, d1),d2);
        //dmx = max(dmx,-d3);
        return smin(max(max(dspr, -dms),d4), dline, 0.);
}

float springAndTwoLine(vec3 p)
{
        float d1 = springAndLine(p);
        p.xz=-p.xz;
        float d2 = springAndLine(p);
        return min(d1,d2);
}

vec2 frctE(vec2 po, vec2 px, vec2 py, vec2 p) {
        // ?????? 4 ??: ?po, ?px, ?py ??? pxy = (po+(px-po)+(py-po))?
        // ???????????? E:(po-px-pxy-py),? E ??????????
        // ??????,?p????????????,??????????? E ??,??????????p????
        float e = po.x, f = po.y,
                a = px.x - e, b = px.y - f,
                c = py.x - e, d = py.y - f,
                g = a * d - b * c;
        mat3 Mrst = mat3(px - po, 0, py - po, 0, po, 1);
        mat3 Mdef = mat3(d, -b, 0, -c, a, 0, c * f - d * e, -(a * f - b * e), g) / g;
        p = (Mdef * vec3(p, 1)).xy;
        p = fract(p);
        p = (Mrst * vec3(p, 1)).xy;
        return p;
}

// ??
float distBorder(vec2 o, vec3 dir, vec2 po, vec2 pa, vec2 pb)
{
        vec2 nv = vec2(-1,1), dx = normalize(pa - po).yx * nv, dy = normalize(pb - po).yx * nv;
        if(dot(dx, dir.xy)>0.)dx = -dx;
        if(dot(dy, dir.xy)>0.)dy = -dy;
        float d, dm = 1e8, k =  length(dir)/length(dir.xy);
        d  = dot(o - pa, dx);
        if(d >0.){
             //dm =mix(dm, min(dm, d*k), d>0.?1.:0.); // ?
             dm = min(dm, d*k);
        }
        d  = dot(o - pb, dx);
        if(d >0.)dm = min(dm, d*k);
        d  = dot(o - pa, dy);
        if(d >0.)dm = min(dm, d*k);
        d  = dot(o - pb, dy);
        if(d >0.)dm = min(dm, d*k);
        return dm;
}

// 18:18 ??
float sdBox(vec2 o,vec2 po, vec2 pa, vec2 pb)
{
        vec2 nv = vec2(-1,1), 
             dx = normalize(pa - po).yx * nv, 
             dy = normalize(pb - po).yx * nv,
             ct = po +((pa-po)+(pb-po))*.5;
        float d, dm = -1e8;
        if(dot(ct-pa,dx)>0.)dx=-dx;
        d  = dot(o - pa, dx);
        dm = max(dm, d);
        
        if(dot(ct-pb,dx)>0.)dx=-dx;
        d  = dot(o - pb, dx);
        dm = max(dm, d);
        
        if(dot(ct-pa,dy)>0.)dy=-dy;
        d  = dot(o - pa, dy);
        dm = max(dm, d);
        
        if(dot(ct-pb,dy)>0.)dy=-dy;
        d  = dot(o - pb, dy);
        dm = max(dm, d);
        return dm;
        
}

float stoneMesh(vec3 p)
{
        float dz = p.z - round(p.z /400.)*400.;
        dz = abs(dz) -R-r-.1;
        if(dz>0.)return dz+.05;
        float x1 = 2. * PI * R, y1 = x1 * tan(A), kyx = y1 / x1;
        
        
        float cutA = .25 + .5*level;
        vec3 e = vec3(R*cos(TAU*cutA),y1*cutA, R*sin(TAU*cutA));
        vec3 ny = normalize(vec3(0,y1,x1)); 
        ny.xz = rot(TAU*cutA)*ny.xz; // ??
        
        float chang = ratio* R;
        vec2 newx = (e.xy + ny.xy * chang     )*2.;
        vec2 newy = (e.xy + ny.xy * chang * 1.)*2. * vec2(-1,1);
        vec2 fp = p.xy;
        vec2 po=vec2(0);
        
        
        //newx = vec2(2,-2)*.5;newy=vec2(3);
        
        vec2 ct = po + newx*.5+newy*.5;
        fp = frctE(po, po+newx, po+newy, fp)-ct;
        
        vec2 n1=newx.yx*vec2(-1,1);
        vec2 n2=newy.yx*vec2(-1,1);
        float border = 1e8; 
        /*
        border = min(border,abs(dot(fp+ct-(po+newx), n1)));
        border = min(border,abs(dot(fp+ct-(po+newx), n2)));
        border = min(border,abs(dot(fp+ct-(po+newy), n1)));
        border = min(border,abs(dot(fp+ct-(po+newy), n2)));
        */
        
        //vec2 gd=gDir.xy;
        
        border = distBorder(fp+ct, gDir, po, po+newx, po+newy)  + .03;
        
        float box = -1e8;// sdBox(fp+ct,po,po+newx, po+newy  );
        
        //return min(border, length(  vec3(fp,p.z)  )-6.3);
        return min(border, max(box-.04, springAndTwoLine(vec3(fp,p.z - round(p.z /400.)*400.))));
}

float map(vec3 p) {
        float t = time;
        p.xz *= rot(-.2);
        return stoneMesh(p);
}

void main(void) {
        
        vec4 O = vec4(0.0);
        vec2 v = gl_FragCoord.xy;
        
        ratio = 3.+6.*(.5+.5*sin(time*.3+1.));
        A = PI / (3.5+3.*(.5+.5*cos(time*.456+.5)));
        level = ctrlLevel;
        
        
        vec4 bkclr = vec4(.5,.2,.3,1);
        O = bkclr;
        vec2 R = resolution.xy,
                u = (v + v + .1 - R) / R.y,
                m = (mouse*resolution.xy.xy * 2. - R) / R.y;
        
        // spalmer 
        
        
        
        vec3 q = vec3(u,time*0.).xzy * 18.;
        //if(mouse*resolution.xy.x<R.x*.51)q=q.yzx;
        //q = qq(u*18.);
        float mq = map(q);
        //O.rgb = vec3(mq < 0., mq<18.&& mq > 0., mq>18.) * abs(sin(9. * mq))// * abs(tanh(mq*.04))
                ;//*.4+.3;
        
        vec3 o = vec3(0, 1, -75),
                r = gDir = normalize(vec3(u, 2)),
                e = vec3(0, 1e-3, 0),
                p, n,
                s = normalize(vec3(-1, -2, -3));
        
        float d, t, f, g, c;
        for (int i; i < 256 && t < 1115.; i++) {
                p = o + r * t;
                d = map(p);
                if (d < .02) break;
                t += d;
        }
        if (d < .02) {
                O *= 0.;
                n = normalize(vec3(map(p + e.yxx), map(p + e), map(p + e.xxy)) - d);
                f = .5 + .5 * dot(n, s);
                g = max(dot(n, s), 0.);
                c = 1. + pow(f, 200.) - f * .3; // 665.352.6.542.9958.8.63
                O += c * g;
                O *= mix(bkclr, vec4(1.5,.5,0,1), exp(-.01*t));
        }
        
        glFragColor = O;
}

        //jj=j1;if(dt2<dt1)jj=j2;
        
        //vec3 nx; ny; nz;
        //ny = rot(jj.x/R) * normalize(vec3(0,y1,x1));
        //nz = vec3(0,-1,0);
        //nx = normalize(cross(ny,nz));
        //nz = cross(nx, ny);
