#version 420

// original https://www.shadertoy.com/view/3dSBRG

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SylvainLC 2020 
// Use mouse to move camera and rotate the rocket.
// This is created essentially from the rendering code of IQ with referencies below.
// Modeled the rocket using Vesica revolution and adding rounding to give it balloon shape
// Arches joining the Rockets and motors are made of 2D truncated arcs of cirles with Extrussion.
// Used a symetry to replicate 3 times the motors around the rocket. You may add more motors modifing line 81 in common
// The rocket is carved and you can see inside thru the portholes.
// Had a lot of fun painting the rocket with gray parts, the IQ rendering code is impressive.
// Added later the alien and the crater, unfortunately slowing the rendering on mobile.

// Step #2 of the LIVE Shade Deconstruction tutorial for "Happy Jumping"
// Created by inigo quilez - iq/2019
// https://www.youtube.com/watch?v=Cfe5UQ-1L9Q

// Step 1: https://www.shadertoy.com/view/Wl2SRw
// Step 2: https://www.shadertoy.com/view/3ljSzw
// Step 3: https://www.shadertoy.com/view/ttjXDz
// Step 4: https://www.shadertoy.com/view/tljSDz
// Final:  https://www.shadertoy.com/view/3lsSzf    

mat2 rotationMatrix(float angle)
{
    float s=sin(angle), c=cos(angle);
    return mat2( c, -s, s, c );
}

// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

//-------------------------------------------------

// https://www.shadertoy.com/view/4lyfzw
vec2 opRevolution( in vec3 p, float w )
{
    return vec2( length(p.xz) - w, p.y );
}
float opExtrussion( in vec3 p, in float sdf, in float h )
{
    vec2 w = vec2( sdf, abs(p.z) - h );
      return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

//-------------------------------------------------

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

// http://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);

    float b = sqrt(r*r-d*d); // can delay this sqrt
    return ((p.y-b)*d > p.x*b) 
            ? length(p-vec2(0.0,b))
            : length(p-vec2(-d,0.0))-r;
}
float sdCircle(vec2 p, float r)
{
    return length(p)-r; 
}

vec2 sdRocket( vec3 pos )
{
    float m = 2.; // material 2 = red, 3 = gray , 4 = portholes
    // try to box in a sphere for optimization
    if ( length(pos) > 1.4 ) { return vec2(length(pos)-1.3,2.); }
    float d = 1e10;
    // body
    vec3 q;
    q = pos - vec3(0.,0.,0.);
    d = min( d, -0.01+abs(-0.1 + sdVesica(opRevolution(q,0.0), 1.4, 1.1 )));  // try with ABS to make empty space into the shape
    if ( pos.y > 0.74 ) { m = 3.; } // painting
    { 
        float dist = sdVesica(opRevolution(q,0.0), 1.4, 1.17 );
        if ( d > dist ) { d=dist ; m = 3.; }   
    }
    if ( pos.y < -0.90 ) { m = 3.; } // painting bottom 
    // strips 
    float vangle = atan(pos.z,pos.x); // angle from left to front
    if ( sin(vangle*3.) <.5 ) {
    if ( pos.y < -0.3  && pos.y > -0.5 && cos(vangle*6.)>.0 )  { m = 3. ; }
    if ( pos.y < -0.5  && pos.y > -0.65 && cos(vangle*6.)<.0 ) { m = 3. ; }
    if ( pos.y < -0.65 && pos.y > -0.80 && cos(vangle*6.)>.0 ) { m = 3. ; }
    }
    // 3 sectors for engines
    const float an = 6.283185/3.0;
    q = pos;
    q.xz = rotationMatrix(an*0.25)*q.xz; // rotation to position first piece
    float fa = (atan(q.z,q.x)+an*0.5)/an; // thanks to IQ
    float sym = an*floor(fa);
    q.xz = rotationMatrix(sym)*q.xz;
    // d = min( d, );
    float ln = -0.05 + sdVesica(opRevolution(vec3(q.x-.6,q.y+.8,q.z),0.0), 0.65, 0.5 ) ;
    if ( ln < d ) { m = 2. ; d = ln ; }
    // cut the bottom
    d = smax( d, -pos.y-1.1, 0.05 );
    if ( pos.y < -0.96 ) { m = 3.; } // painting bottom 
    // link between engines and rocket's body
    q = vec3(q.x+0.1,q.y+1.13,q.z+0.0);
    float lnd = sdCircle(q.xy, 1.00 );
        lnd = max(lnd,-sdCircle(q.xy+vec2(-0.3,0.3),0.6));
        lnd = max(lnd,-q.x+0.1);
        lnd = max(lnd,q.x-0.8);
        lnd = max(lnd,-q.y+0.2);
    ln = opExtrussion (q,lnd,0.02)-0.01;
    // d = min( d, ln );
    if ( ln < d ) { m = 3. ; d = ln ; }
    // 3 porthole
    q = pos;
    ln = sdSphere(q-vec3(0.0,0.37,0.37), 0.1 ); if ( ln < -d ) { m = 3. ; d = -ln ; }
    ln = sdSphere(q-vec3(0.0,0.37-0.38,0.37), 0.1 ); if ( ln < -d ) { m = 3. ; d = -ln ; }  
    vec3 r = q ; r.xz*=rotationMatrix(an) ;
    ln = sdSphere(r-vec3(0.0,0.37-0.38,0.37), 0.1 ); if ( ln < -d ) { m = 3. ; d = -ln ; }  
    r.xz*=rotationMatrix(an) ;
    ln = sdSphere(r-vec3(0.0,0.37-0.38,0.37), 0.1 ); if ( ln < -d ) { m = 3. ; d = -ln ; }  
    ln = sdSphere(q-vec3(0.0,0.37-0.38*2.,0.37), 0.1 ); if ( ln < -d ) { m = 3. ; d = -ln ; }    
    return vec2(d,m);

}

float sdCone( vec3 p, vec2 c )
{
    // c is the sin/cos of the angle
    vec2 q = vec2( length(p.xz), -p.y );
    float d = length(q-c*max(dot(q,c), 0.0));
    return d * ((q.x*c.y-q.y*c.x<0.0)?-1.0:1.0);
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

vec2 sdStick(vec3 p, vec3 a, vec3 b, float r1, float r2)
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return vec2( length( pa - ba*h ) - mix(r1,r2,h*h*(3.0-2.0*h)), h );
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

vec3 animateAlien(vec3 pos,float atime) {
    float sequence = 10.*fract(atime/20.);
    vec3 q = pos;
    if (sequence < 5. ) {
        q.y+=2.+2.*cos(3.14*sequence/5.);
    } else if (sequence >7.) {
        q.y-=10.*(-1.+1.*cos(3.14*(7.-sequence)/3.));
    }
    return q;
}

vec3 animateCamera(vec3 pos,float atime) {
    float sequence = 10.*fract(atime/20.);
    vec3 q = pos;
    return q;
    if (sequence < 3. ) { // not finished
        q.x+=-2.*(1.+cos(3.14*sequence/3.));
    } else if (sequence >7.) {
        q.x+=-2.*(1.+sin(3.14*(sequence-7.)/3.));
    }
    return q;
}

vec3 animateRocket(vec3 pos,float atime,float spin) {
    float sequence = 10.*fract(atime/20.);
    vec3 q = pos;
        q -= vec3(0,0.9,-1.6);
        q.xz*=rotationMatrix(-atime*3.14/3.0);
        q -= vec3(3.,0.,0.);
        q -= vec3(0.,1.2+0.2*sin(atime*5.0),0.);
        q.yz*=rotationMatrix(cos(atime*5.0)/5.-3.14/2.0);
        q.xz*=rotationMatrix(1.2*3.14/2.0);
//        q.xz*=rotationMatrix(1.*3.14/2.0);
    q.xz*=rotationMatrix(spin+atime);  // spin
    return q;
}

vec2 sdCrater( vec3 pos )
{
    float d=1e10;
    if ( length(pos) > 1.95 ) { 
        d=length(pos)-1.8; 
    } else {
 // float d = sdCappedCone(pos-vec3(0.0,1.1,-1.0),0.7,1.0,0.5);
    vec3 q = pos;
    q.z-=q.y*q.y/6.;
    q.xz=q.xz*rotationMatrix(1.9);
    q.zy=q.zy*rotationMatrix(q.y/20.); // bend
    d = sdCone(q-vec3(0.,2.5,0.),vec2(sin(3.14/6.),cos(3.14/6.)));
   // q = pos;
    d = smax(d,-length(q.xz)+0.52,0.3 );
    // small craters
    q = pos; 
    q.xz=q.xz*rotationMatrix(0.9);
    q.zy=q.zy*rotationMatrix(q.y/20.); // bend
    d=smin(d,smax(sdCone(q-vec3(0.0,1.2,1.3),vec2(sin(3.14/8.),cos(3.14/8.))),-sdSphere(q-vec3(0.,1.0,1.3),0.3),0.1),0.1);
    // small craters
    q = pos; 
    q.xz=q.xz*rotationMatrix(-0.9);
    q.zy=q.zy*rotationMatrix(q.y/20.); // bend
    d=smin(d,smax(sdCone(q-vec3(0.0,0.7,1.3),vec2(sin(3.14/6.),cos(3.14/6.))),-sdSphere(q-vec3(0.,0.5,1.3),0.15),0.1),0.1);
    }    
    // cut the bottom
//    d = smax(d,-q.y,0.2 );
    // ground
    d = smin(d,(pos.y + 0.1*sin(pos.z)+0.1*sin(pos.x)),0.05 );
//    d = pos.y + 0.1*sin(pos.z)+0.1*sin(pos.z);

    vec2 res = vec2 ( d, 4. );
    return res;
}    

vec2 sdAlien ( vec3 pos ) {
    if ( length(pos) > 1.4 || pos.y < -2.0 ) { return vec2(length(pos)-1.3,2.); }
    vec3 q = pos;
    q.y-=abs(0.1*sin(time*5.));
    q.yz*=rotationMatrix(-0.05+0.05*sin(time*5.));
    q.xz*=rotationMatrix(0.10*sin(time*10.));
    float d = sdEllipsoid(q,vec3(0.45,0.20,0.45)) ;
    q.z-=.1;
    vec3 top = vec3(0.15,0.5,0.2);
    vec2 sti = sdStick(q,vec3(0.1,0.,0.),top,0.15,0.08);
    d = smin(d,sti.x,0.05);
    d = smin(d,sdSphere(q-top,.12),0.03);
    top=vec3(-0.15,0.5,0.2);
    sti = sdStick(q,vec3(-0.1,0.,0.),top,0.15,0.08);
    d = smin(d,sti.x,0.05);
    d = smin(d,sdSphere(q-top,.12),0.03);
    top=vec3(0.0,0.70,0.25);
    sti = sdStick(q,vec3(0.,0.,0.),top,0.15,0.08);
    d = smin(d,sti.x,0.05);
    d = smin(d,sdSphere(q-top,.14),0.03);
    vec2 res = vec2 ( d, 5. );
    // neck
    sti = sdStick(q,vec3(0.,0.,-0.2),vec3(0.,-1.,-0.2),0.25,0.30);
    d = smin(d,sti.x,0.05);
    // mouth
    top=vec3(0.0,0.02,0.04);
    d = smin(d,sdTorus(q-top,vec2(.35,.03)),0.01);
    res = vec2 ( d, 5. );
    top=vec3(0.0,-0.02,0.04);
    d = smin(d,sdTorus(q-top,vec2(.35,.03)),0.01);
    res = vec2 ( d, 5. );
    // eyes
    // 1
    top = vec3(0.15,0.5,0.26);
    float s = sdSphere(q-top,.08);
    if ( s < res.x ) { res.x=s ; res.y=6.; }
    top = vec3(0.14,0.5,0.30);
    s = sdSphere(q-top,.05);
    if ( s < res.x ) { res.x=s ; res.y=7.; }
    // 2
    top = vec3(-0.15,0.5,0.26);
    s = sdSphere(q-top,.08);
    if ( s < res.x ) { res.x=s ; res.y=6.; }
    top = vec3(-0.14,0.5,0.30);
    s = sdSphere(q-top,.05);
    if ( s < res.x ) { res.x=s ; res.y=7.; }
    // 3
    top=vec3(0.0,0.70,0.32);
    s = sdSphere(q-top,.09);
    if ( s < res.x ) { res.x=s ; res.y=6.; }
    top=vec3(0.0,0.69,0.38);
    s = sdSphere(q-top,.05);
    if ( s < res.x ) { res.x=s ; res.y=7.; }
    
    return res;
}

vec2 map( in vec3 pos, float atime )
{
        vec3 q = pos;
    // rocket
    vec2 dm = sdRocket(animateRocket(q,atime,10.*mouse.y*resolution.xy.y/resolution.y)); 
    float d = dm.x;
    vec2 res = vec2(d,dm.y);
    // crater
    q = pos;
    // q.x+=-4.;
    // q = mod(q+0.5*7.,7.)-0.5*7.;
//    q.xz*=rotationMatrix(0.3);
//    q = pos-7.*clamp(round(q/7.),-1.0,1.0);
    dm = sdCrater(q-vec3(0.0,0.,-1.0)); 
    if ( dm.x < d ) { d = dm.x; res = vec2(d,dm.y); }
    // Alien
    dm = sdAlien(animateAlien(q,atime)-vec3(0.0,1.5,-1.0)); 
    if ( dm.x < d ) { d = dm.x; res = vec2(d,dm.y); }
    

    /* temp sphere 
    {
      d = sdSphere(pos-vec3(0.0,1.0,0.0),1.0);
      if( d < res.x ) res = vec2(d,1.0);
    } */
       
    return res;
}

vec2 castRay( in vec3 ro, in vec3 rd, float time )
{
    vec2 res = vec2(-1.0,-1.0);

    float tmin = 0.5;
    float tmax = 20.0;
    
    float t = tmin;
    for( int i=0; i<512 ; i++ )
    {
        vec2 h = map( ro+rd*t, time );
        if( h.x<0.001 )
        { 
            res = vec2(t,h.y); 
            break;
        }
        t += h.x;
        if (t>=tmax) break;
    }
    
    return res;
}

/* vec3 calcNormal( in vec3 pos, float time )
{
    vec3 n = vec3(0.0);
    for( int i=min(frames,0); i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e,time).x;
    }
    return normalize(n);    
} */

vec3 calcNormal( in vec3 pos, float time )
{
    vec2 e = vec2(0.0005,0.0);
    return normalize( vec3( 
        map( pos + e.xyy, time ).x - map( pos - e.xyy, time ).x,
        map( pos + e.yxy, time ).x - map( pos - e.yxy, time ).x,
        map( pos + e.yyx, time ).x - map( pos - e.yyx, time ).x ) );
}

float calcOcclusion( in vec3 pos, in vec3 nor, float time )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = map( opos, time ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

vec3 render( in vec3 ro, in vec3 rd, float time )
{ 
    // sky dome
//     vec3 col = vec3(0.5, 0.8, 0.9) - max(rd.y,0.0)*0.5;
//    vec3 col = vec3(0.2, 0.2, 0.2) - max(rd.y+0.60,0.00)*0.2;
//      vec3 col = vec3(0.1, 0.1, 0.1) - max(rd.y+0.00,0.00)*0.5;
    // sky dome
    vec3 col = vec3(0.5, 0.8, 0.9) - max(rd.y,0.0)*0.5;
    // sky clouds
    vec2 uv = 1.5*rd.xz/rd.y;
    float cl  = 1.0*(sin(uv.x)+sin(uv.y-time)); uv *= mat2(0.8,0.6,-0.6,0.8)*2.1;
          cl += 0.5*(sin(uv.x)+sin(uv.y-time));
    col += 0.1*(-1.0+2.0*smoothstep(-0.1,0.1,cl-0.4));
    // sky horizon
    col = mix( col, vec3(0.5, 0.7, .9), exp(-10.0*max(rd.y,0.0)) );    
    
    vec2 res = castRay(ro,rd, time);
    if( res.y>-0.5 )
    {
        float t = res.x;
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos, time );
        vec3 ref = reflect( rd, nor );
        
        col = vec3(0.2);
        float ks = 1.0;

        if( res.y>6.5 ) // black
        { 
            col = vec3(0.00,0.00,0.00);
        }
        else if( res.y>5.5 ) // white
        { 
            col = vec3(0.5,0.5,0.5);
        }
        else if( res.y>4.5 ) // alien
        { 
            col = vec3(0.03,0.12,0.03);
        }
        else if( res.y>3.5 ) // crater
        { 
            col = vec3(0.12,0.05,0.0);
        }
        else if( res.y>2.5 ) // rocket gray part
        { 
            col = vec3(0.1,0.1,0.1);
        }
        else if( res.y>1.5 ) // rocket red part
        { 
            col = vec3(0.5,0.00,0.00);
        }
        else // terrain
        {
            col = vec3(0.02,0.02,0.02);
        }
        
        // lighting
        vec3  sun_lig = normalize( vec3(0.6, 0.35, 0.5) );
        float sun_dif = clamp(dot( nor, sun_lig ), 0.0, 1.0 );
        vec3  sun_hal = normalize( sun_lig-rd );
        float sun_sha = step(castRay( pos+0.001*nor, sun_lig,time ).y,0.0);
        float sun_spe = ks*pow(clamp(dot(nor,sun_hal),0.0,1.0),8.0)*sun_dif*(0.04+0.96*pow(clamp(1.0+dot(sun_hal,rd),0.0,1.0),5.0));
        float sky_dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float bou_dif = sqrt(clamp( 0.1-0.9*nor.y, 0.0, 1.0 ))*clamp(1.0-0.1*pos.y,0.0,1.0);

        vec3 lin = vec3(0.0);
        lin += sun_dif*vec3(8.10,6.00,4.20)*sun_sha;
        lin += sky_dif*vec3(0.50,0.70,1.00);
        lin += bou_dif*vec3(0.40,1.00,0.40);
        col = col*lin;
        col += sun_spe*vec3(8.10,6.00,4.20)*sun_sha;
        
        col = mix( col, vec3(0.5,0.7,0.9), 1.0-exp( -0.0001*t*t*t ) );
    }

    res.x = min(res.x, 20.);
    vec3 fog = vec3(0.5, 0.7, 0.9) - max(rd.y+0.60,0.00)*0.2;
    col = mix(col, fog, smoothstep(0., .99, res.x*res.x/400.));
    
    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    float time = time;

    time *= 0.9;

    // camera    
    float an = mouse*resolution.xy.x == 0. ? 0. : 10.*(-0.5+mouse.x*resolution.xy.x/resolution.x);
//    an = 0.5*sin(time);
    vec3  ta = vec3( 0.0, 1.5, -1.5);
    vec3  ro =  vec3 (0.,2.65,3.8);
    ro = animateCamera(ro,time);
    ro.xz = ro.xz * rotationMatrix(an);

    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 rd = ca * normalize( vec3(p,1.8) );

    vec3 col = render( ro, rd, time );

    col = pow( col, vec3(0.4545) );

    glFragColor = vec4( col, 1.0 );
}
