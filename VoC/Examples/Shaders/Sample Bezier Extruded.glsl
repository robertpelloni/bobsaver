#version 420

// original https://www.shadertoy.com/view/7dyBz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Extrude a SDF along a Quadratic Bezier segment, correctly oriented to tangent
//
// based on IQ's https://www.shadertoy.com/view/ldj3Wh , I just added orientation 
//
// added a couple of minor optimizations
// might be worth passing in the up vector instead of just using (0,1,0)
// made it shiny because we got some likes :)

#define TWIST 1 // set this to zero if you want to see just spline oriented sdf

// returns xyz = position, w = spline position (t)
vec4 sdBezierExtrude(vec3 pos, vec3 A, vec3 B, vec3 C)
{    
    // check for colinear
    //if (abs(dot(normalize(B - A), normalize(C - B)) - 1.0) < 0.0001)
    //    return sdLinearSegment(pos, A, C);

    // first, calc curve T value
    vec3 a = B - A;
    vec3 b = A - 2.0*B + C;
    vec3 c = a * 2.0;
    vec3 d = A - pos;

    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;
    float t;

    if(h >= 0.0) 
    { 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        t = clamp(uv.x+uv.y-kx, 0.0, 1.0);
        // 1 root
    }
    else
    {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 _t = clamp( vec3(m+m,-n-m,n-m)*z-kx, 0.0, 1.0);
        // 3 roots, but only need two
        vec3 r1 = d + (c + b * _t.x) * _t.x;
        vec3 r2 = d + (c + b * _t.y) * _t.y;
        //t = length(r2.xyz) < length(r1.xyz) ? _t.y : _t.x;
        t = dot(r2,r2) < dot(r1,r1) ? _t.y : _t.x; // quicker
        
    }
    
    // now we have t, calculate splineposition and orient to spline tangent
    //t = clamp(t,0.1,0.9); // clamp spline start/end
    
    vec3 _tan = normalize((2.0 - 2.0 * t) * (B - A) + 2.0 * t * (C - B));  // spline tangent
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 binormal = normalize(cross(up, _tan));
    vec3 _normal = cross(_tan, binormal);
//    vec3 t1 = normalize(cross(_normal, _tan));
    vec3 t1 = cross(_normal, _tan); // no need to normalize this?
    mat3 mm = mat3(t1, cross(_tan, t1), _tan);
    pos.xyz = mix(mix(A, B, t), mix(B, C, t), t) - pos; // spline position
    return vec4(pos.xyz*mm, t);
}

// iq
float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// iq
float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

mat2 rot(float a)
{
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

float map( in vec3 pos )
{
    vec3 a = vec3(-5.5,0.0,0.0);
    vec3 b = vec3(0.0,sin(time*1.1)*6.0,(0.5+sin(time*2.8)*0.5)*5.0);
    vec3 c = vec3(5.5,0.0,0.0);
    vec4 bz = sdBezierExtrude(pos,a,b,c);

    // twist is optional...
    #if TWIST==1
    {
        float twist = (0.5+sin(time*1.8)*0.5)*1.1;
        bz.xy *= rot( (3.14*twist) * bz.w);
    }
    #endif

    float d;
    //if (mouse*resolution.xy.z>0.5)
    //    d = sdTorus(bz.xyz,vec2(0.75,0.35)); // use a torus
    //else
    //{
        d = sdBox(bz.xyz, vec3(1.2,0.1,0.01))-0.15; // use a box
        d = min(length(bz.xyz)-0.3,d); // show the spline center with a sphere  :)
    //}
    #if TWIST==1
    d*=0.8;  //twist modifier will distort the distance, so adjust it so it doesn't overshoot
    #endif
    
    return d;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.01;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
                      e.yyx*map( pos + e.yyx*eps ) + 
                      e.yxy*map( pos + e.yxy*eps ) + 
                      e.xxx*map( pos + e.xxx*eps ) );
}
    
#define AA 0

void main(void)
{
     // camera movement    
    float an = 0.5*time;
    
    float yy = 4.0;
    
    vec3 ro = vec3( 9.*cos(an), yy, 9.0*sin(an) );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
        #else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
        #endif

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );

        // raymarch
        const float tmax = 50.0;
        float t = 0.0;
        for( int i=0; i<128; i++ )
        {
            vec3 pos = ro + t*rd;
            float h = map(pos);
            if( h<0.01 || t>tmax ) break;
            t += h;
        }
    
        // shading/lighting
        vec3 col = vec3(0.22,0.1,0.4)*smoothstep(1.0,0.0,abs(p.y));
        if( t<tmax )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);
            vec3 rf = reflect(ww, nor);
            float sha = map(pos+rf) + .5;
            float factor = sha*length(sin(rf*3.)*0.5+0.5)/sqrt(2.);
            col = mix(vec3(0.15,0.05,0.26), vec3(0.28,0.6,0.2), factor) + pow(factor*0.7, 6.);
        }

        // gamma        
        col = sqrt( col );
        tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    glFragColor = vec4( tot, 1.0 );
}
