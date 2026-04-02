#version 420

// original https://www.shadertoy.com/view/lsBSWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Burning balls by nimitz (twitter: @stormoid)

/*
    Temperature curves from: http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
    Ideally, we would have a similar function that returns in the 0...1 range.

    Using antialiasing form iq (https://www.shadertoy.com/view/4sjSz3)
    With a simplified shading function for the edges, ends up being decently fast.
*/

//Allows you to change the relative color of a given temperature at fixed intensity.
#define TEMP_MULT 1.

//#define SHOW_EDGES_ONLY

#define ITR 110
#define FAR 35.
#define tau 6.2831853
#define pi 3.14159265

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,-s,s,c);}
vec2 ou( vec2 d1, vec2 d2 ){return (d1.x<d2.x) ? d1 : d2;}

vec2 map(vec3 p)
{   
    float a = atan(p.x, -p.z)*11./tau;
    float id = floor(a+.5);
    p.zx *= mm2(id*tau/11.);
    p.z += id*.3+5.5;
    vec2 d = vec2((length(p+vec3(0,-id*0.005,0))-.45), id+5.5); //Can you see the hack? :P
    d = ou(d,vec2(p.y+.51,0.));
    return d;
}

//Ligth color and distance
vec2 ldist(vec3 p)
{
    float a = atan(p.x, -p.z)*11./tau;
    float id = floor(a+.5);
    p.zx *= mm2(id*tau/11.);
    p.z += id*.3+5.5;
    vec2 d = vec2((length(p)),id+5.5);
    return d;
}

vec3 normal(in vec3 p)
{  
    vec2 e = vec2(-1., 1.)*0.005;   
    return normalize(e.yxx*map(p + e.yxx).x + e.xxy*map(p + e.xxy).x + 
                     e.xyx*map(p + e.xyx).x + e.yyy*map(p + e.yyy).x );
}

//Curves from: http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
vec3 ctemp(in float t)
{
    t /= 100./TEMP_MULT;
    vec3 col = vec3(0);
    if (t< 66.)
    {
        col.r = 255.;
        col.g = 99.4708*log(t) - 161.11957;
        col.b = 138.51773*log(t-10.) - 305.04479;
    }
    else
    {
        col.r = 329.698727446 * pow(t-60., -0.1332047592);
        col.g = 288.1221695283 * pow(t-60., -0.0755148492);
           col.b = 138.5177312231 * log(t-10.) - 305.0447927307;
    }
    col /= 255.;
    return clamp(col,0.,1.);
}

vec3 shade(in vec3 pos, in float id)
{
    vec3 col = vec3(0.);
      
    //emissive
    if (id >0.)
    {
        float temp = id * 360.;
        vec3 ecol = ctemp(temp)*temp*0.00035;
        col += ecol;
    }
    else
    {
        vec2 tp = ldist(pos);
        float temp = tp.y * 360.;
        vec3 ecol2 = ctemp(temp)*temp*0.00035;
        float atn = clamp(exp(-1.64*tp.x), 0., 1.);
        ecol2 *= atn;
        col += ecol2;
    }
    return clamp(col,0.,1.);
    
}

//soft shadows and ao from iq
float shadow(in vec3 ro, in vec3 rd, in float mint, in float tmax)
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<7; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, 4.0*h/t );
        t += clamp( h, 0.02, 0.20 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

}

float calcAO(in vec3 pos, in vec3 nor)
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0*occ, 0., 1.);    
}

vec3 cookt(in vec3 pos, in vec3 n, in vec3 rd, in vec3 l, in vec3 lcol, in vec3 alb)
{
    //material data (should be passed in)
    const float rough = 0.45;
    const vec3 F0 = vec3(.7);
    const float kr = .55; //diff/spec ratio
    
    float nl = dot(n, l);
    float nv = dot(n, -rd);
    vec3 col = vec3(0.);
    if (nl > 0. && nv > 0.)
    {
        vec3 haf = normalize(l - rd);
        float nh = dot(n, haf); 
        float vh = dot(-rd, haf);
        
        vec3 dif = alb*nl;
        
        float a = rough*rough;
        float a2 = a*a;
        float dn = nh*nh*(a2 - 1.) + 1.;
        float D = a2/(pi*dn*dn);
        
        float k = pow( rough*0.5 + 0.5, 2.0 )*0.5;
        float nvc = max(nv,0.);
        float gv = nvc/(nvc*(1.-k) + k);
        float gl = nl/(nl*(1.-k) + k);
        float G = gv*gl;

        vec3 F = F0 + (1. - F0) * exp2((-5.55473 * vh - 6.98316) * vh); //Horner       
        
           vec3 spe = D*F*G/(4.*nl*nv);
        col = mix(spe,dif,kr);
        col *= shadow( pos, l, 0.05, 10.)*0.5+0.5;
        col *= lcol;
    }
    return col;
}

vec3 shadeFull(in vec3 pos, in vec3 n, in vec3 rd, in vec3 l, in vec3 lcol, in float id)
{
    vec3 col = vec3(0);
    vec3 alb = vec3(0.);
    if (id == 0.)
    {
        float f = mod(floor(pos.z) + floor(pos.x), 2.);
        alb = f*vec3(1)*0.1+0.4;
    }
    
    //emissive
    if (id >0.)
    {
        float temp = id * 360.;
        col = cookt(pos, n, rd, l, mix(lcol,alb,smoothstep(0.,5000.,temp)), alb);
        vec3 ecol = ctemp(temp)*temp*0.00035;
        col += ecol;
    }
    else
    {
        col = cookt(pos, n, rd, l, lcol, alb);
        vec2 tp = ldist(pos);
        float temp = tp.y * 360.;
        vec3 ecol2 = ctemp(temp)*temp*0.00035;
        float atn = clamp(exp(-1.64*tp.x)-0.02, 0., 1.);
        ecol2 *= atn;
        col += ecol2;
    }
    return clamp(col,0.,1.);
}

void main( void )
{    
    vec2 bp = gl_FragCoord.xy/resolution.xy;
    vec2 p = bp-0.5;
    p.x*=resolution.x/resolution.y;
    //vec2 mo = iMouse.xy / iResolution.xy-.5;
    vec2 mo=vec2(0.0,0.0);
    mo = (mo==vec2(-.5))?mo=vec2(0.,-.1):mo;
    mo.x *= resolution.x/resolution.y;
    vec3 ro = vec3(0.,0.2,13.);
    vec3 rd = normalize(vec3(p,-1.5));
    mat2 mx = mm2(time*.2+mo.x*3.);
    mat2 my = mm2(-0.15+mo.y*.2); 
    ro.yz *= my;rd.yz *= my;
    ro.xz *= mx;rd.xz *= mx;
    
    float px = .45/resolution.y;
    
    vec3 col = vec3(0.0);
    vec3 ligt = normalize( vec3(-.4, 0.4, -0.2) );
    float edl = clamp(dot(ligt, rd),0.,1.);
    vec3 lcol = vec3(1)*.45;
    vec3 bgcol = vec3(0.05) + pow(edl,13.)*lcol;
    
    vec4 res = vec4(0.0);
    float t = 0.;
    vec2 oh = vec2(1.0);
    bool hit = false;
    vec2 h = vec2(0);
    
    for( int i=0; i<ITR; i++ )
    {
        h = map(ro + t*rd);
        float th1 = px*t;
        float th2 = px*t*3.0;
        
        if( h.x < th1 )
        {
            hit = true;
            break;
        }
        if( (h.x < th2) && (h.x > oh.x) )
        {
            vec3 pos = ro + t*rd;
            vec3  lcol = shade(pos,  h.y );
            float lalp = 1.0 - (h.x-th1)/(th2-th1);
            
            res.xyz += (1.0-res.w)*lalp*lcol;
            res.w   += (1.0-res.w)*lalp;
            if( res.w>0.99 ) break;
        }
        oh = h;

        t += min( h.x, .5 );
        if( t>FAR ) break;
    }
    
    #ifndef SHOW_EDGES_ONLY
    if(hit)
    {
        vec3 pos = ro + t*rd;
        vec3 nor = normal(pos);
        col = shadeFull(pos, nor, rd, ligt, lcol, h.y);
        if (h.y == 0.)
        {
            float ao = calcAO(pos, nor);
            col *= ao*0.3+0.7;
        }
    }
    #endif
     
    col = mix( col, res.xyz/(0.001+res.w), res.w ); //blend 

    col = mix(col,bgcol,smoothstep(20.,FAR,t)); //fog
    
    col *= pow(16.0*bp.x*bp.y*(1. - bp.x)*(1. - bp.y), 0.1); //vign
    
    glFragColor = vec4( col, 1.0 );
}
