#version 420

// original https://www.shadertoy.com/view/4lKyDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 mod289(vec3 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec2 mod289(vec2 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec3 permute(vec3 x) {return mod289(((x*34.0)+1.0)*x);}
float snoise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}
float sdLine( vec2 p, vec2 a, vec2 b, float r )
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
vec2 opRep( vec2 p, vec2 c )
{ 
    return mod(p,c)-0.5*c;
}
vec2 opRepFlip( vec2 p, vec2 c )
{ 
    vec2 fpc = floor(p/c);
    float flip = mod((fpc.x + fpc.y), 2.);
    vec2 ret = p - c*(fpc + 0.5);
    if(flip >= 1.)return ret.yx;
    return ret;
}
vec2 opWarp( vec2 p )
{ 
// return vec2(sin(p.x+2.*p.y),sin(p.y+p.x));
return vec2(p.x+0.1*sin(20.*p.y),p.y);
}

float nnoise( in vec2 uv ){return 0.5 + 0.5*snoise(uv);} //norm [0,1]
float rnoise( in vec2 uv ){return 1. - abs(snoise(uv));} //ridge
float fbm( vec2 x , int oct ) 
{
    float f = 1.98;  // could be 2.0
    float s = 0.49;  // could be 0.5
    float a = 0.0;
    float b = .9;
    for( int i=0; i < 10; i++ )
    {
        if(i >= oct) break;
        float n = nnoise(x);
        a += b * n;          // accumulate values        
        b *= s;
        x *= f;
    }
    return a;
}
float fbmr( vec2 x, int oct ) 
{
    float f = 1.98;  // could be 2.0
    float s = 0.9;  // could be 0.5
    float a = 0.0;
    float b = .4; //0.5
    for( int i=0; i < 10; i++ )
    {
        if(i >= oct) break;
        float n = rnoise(x);
        a += b * n;          // accumulate values        
        b *= s;
        x *= f;
    }
    return a;
}
float fbm2( in vec2 p )
{
    vec2 q = vec2( fbm( p + vec2(0.0,0.0) ,2 ),
                    fbm( p + vec2(5.2,1.3) ,2) );

    return fbmr( p + 2.9*q ,3); //4.0
}
float fbm3( in vec2 p )
{
    vec2 q = vec2( fbm( p + vec2(0.0,0.0) ,2),
                    fbm( p + vec2(5.2,1.3) ,2) );

    vec2 r = vec2( fbm( p + 4.0*q + vec2(1.7,9.2) ,2), //4q
                    fbm( p + 4.0*q + vec2(8.3,2.8) ,2) );
    // r = normalize(r);
    return fbmr( p*2.0 + .4*r , 3); //4.0
}

void main(void)
{
    float aspect = resolution.x/resolution.y;
    float nVal, n, len;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 vUv = uv;
    vUv *= resolution.y/666.;
    vUv.x *= aspect;
    vUv.x += time/50.;
    vec2 c,luv,nuv = vUv*7.;
    //nuv += rnd;

    //background
    n = fbm3(nuv);
    nVal = 2.9*(n-0.06);
    // nVal = 2.5*(n-0.2);
    nVal *= 1.-0.35*clamp(abs(vUv.y-0.5)-0.1,0.,1.);
    nVal *= 1.-0.65*smoothstep(0.27,0.45,(clamp(snoise(3.9*nuv)*nnoise(12.2*nuv)*rnoise(9.2*nuv),0.,1.)));
    n = nVal = clamp(nVal,0.,1.);
    nVal *= 1.14-1.5*clamp(abs(uv.y-0.5)-0.25,0.,1.);
    // nVal *= (0.85+.1*rnoise(21.*nuv)*rnoise(17.*nuv));
    nVal *= (0.9+.1*abs(snoise(14.*nuv)));
    nVal *= (0.9+.1*abs(snoise(24.*nuv)));
    nVal *= (0.86+.14*nnoise(41.*nuv));
    // nVal *= (0.87+0.04*nnoise(0.6*nuv));
    nVal *= (0.95+0.05*fbm(1.2*nuv,2));
    
    //white spots
    // nVal += (1.-n)*2.7*nnoise(3.*nuv)*clamp(snoise(1.3*nuv),0.,1.); 
    // nVal += (1.-n)*1.72*nnoise(4.*nuv)*nnoise(6.3*nuv); 
    nVal += (1.-n)* smoothstep(0.5,1.,1.72*nnoise(3.*nuv)*nnoise(4.3*nuv)); 

    vec2 d1,d2;
    d1 = vec2(rnoise(1.45*nuv),rnoise(1.45*nuv+vec2(-7.2,6.9)));
    
    nuv+=22.;
    float lm = 0.6;
    //lines 1
    luv = nuv;
    luv += 0.08*d1;
    luv += 0.85 * vec2(snoise(.22*luv), snoise(.22*luv + vec2(4.2,-9.1)));
    c = vec2(1.585);
    len = 0.04;
    n = sdLine( 
        opRepFlip(luv,c)
    ,vec2(-c.x*len,-len),vec2(c.x*len,len),0.0001);
    nVal *= lm+(1.-lm)*smoothstep(0.,0.01,n);
    
    //lines 2
    luv = nuv + vec2(-13.2,15.1);
    luv += 0.09*d1;
    luv += 0.85 * vec2(snoise(.22*luv), snoise(.22*luv + vec2(11.2,-9.1)));
    c = vec2(1.79);
    len = 0.04; 
    n = sdLine( 
        opRepFlip(luv,c)
    ,vec2(-c.x*len,len),vec2(c.x*len,-len),0.0001);
    nVal *= lm+(1.-lm)*smoothstep(0.,0.01,n);
    
    //lines 3
    luv = nuv + vec2(27.2,-21.5);
    luv += 0.09*d1;
    luv += 0.85 * vec2(snoise(.22*luv), snoise(.22*luv + vec2(-17.2,8.7)));
    c = vec2(2.07);
    len = 0.085; 
    n = sdLine( 
        opRepFlip(luv,c)
    ,vec2(-c.x*len,0),vec2(c.x*len,0),0.0001);
    nVal *= lm+(1.-lm)*smoothstep(0.,0.01,n);
    
    //lines 3.2
    luv = nuv + vec2(-17.8,-28.5);
    luv += 0.09*d1;
    luv += 0.85 * vec2(snoise(.22*luv), snoise(.22*luv + vec2(-17.2,8.7)));
    c = vec2(1.87);
    len = 0.095; 
    n = sdLine( 
        opRepFlip(luv,c)
    ,vec2(-c.x*len,0),vec2(c.x*len,0),0.0001);
    nVal *= lm+(1.-lm)*smoothstep(0.,0.01,n);
    
    vec3 tint = vec3(1.,0.9,0.7);
    glFragColor = vec4(vec3(nVal)*tint,1.);//vec4(vUv, 0.0, 1.0);
  }
