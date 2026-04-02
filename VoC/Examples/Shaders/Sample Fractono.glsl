#version 420

// original https://www.shadertoy.com/view/WldfDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
float bo(vec3 p , vec3 s){p = abs(p) - s;return max(p.x,max(p.y,p.z));}
float pi = acos(-1.);

#define ITERATIONS 5
float deMengerSponge2(vec3 p, vec3 offset, float scale) {
    vec4 z = vec4(p, 1.0);
    for (int i = 0; i < ITERATIONS; i++) 
    {
        z = abs(z);
        if (z.x < z.y) z.xy = z.yx;
        if (z.x < z.z) z.xz = z.zx;
        //if (z.y < z.z) z.yz = z.zy;
        z *= scale;
        z.xyz -= offset * (scale - 1.0);
        if (z.z < -0.5 * offset.z * (scale - 1.0))
            z.z += offset.z * (scale - 1.0);
    }
    return (length(max(abs(z.xyz) - vec3(1.0, 1.0, 1.0), 0.0))) / z.w;
}

vec2 pmod(vec2 p, float r)
{
    float a = atan(p.x, p.y) + pi / r;
    float n = (pi * 2.) / r;
    a =  floor(a / n) * n;
    return p * rot(-a);
}

vec2 map(vec3 p)
{
    float id = 0.;
    float o = 10.;
    //p.z  += time;

    vec3 op = p;
    p = sin(p);
    
    p.xy *= rot(p.z);
    
    p.xz = pmod(p.xz , 7.);
    p.xz = abs(p.xz) - 1.;

    p.xz = (p.x > p.z)?p.zx:p.xz;
    o  = deMengerSponge2( p , vec3(1.7) , 3. );
    p.xy *= rot(pi / 6.);
    float cab = deMengerSponge2( p , vec3(1.9) , 3.2 ) ;
    if(cab < o)
    {
        o = cab;
        id = 1.;
    }
    op.xy *= rot( sign( sin( op.z ) ) * time + sin( length( op.xy ) * .4 ) );

    op = sin(op) * .6;
    op = clamp(op ,-1. ,1.);
       op = abs(op) - .9;
    float sp = length(op) - .6 ;

    if(sp < o)
    {
        o = sp;
        id = 2.;
    }

    return vec2(o * .9,id);
}

vec2 march(vec3 cp, vec3 rd)
{
    float depth = 0.;
    for(int i = 0; i < 66 ; i++)
    {
        vec3 rp = cp + rd * depth;
        vec2 d = map(rp);
        if(d.x < 0.01)
        {
            return vec2(depth,d.y);
        }
        if(depth > 30.){break;}
        depth += d.x;
    }
    return vec2(-depth,0.);
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    float t = floor(time) + pow(fract(time),1.1);
    p *= rot(t/3.);
    vec3 col = vec3(.1);
    vec3 bcol = col;
    vec3 forward = vec3(0.,0.,0.);
    forward.z += time;
    vec3 cp = vec3(.3,0.,-5.) ;
    cp.xy *= rot(time);
    cp += forward;
    vec3 target = vec3(2.,0.,0.) ;
    target.y += sin( t/4. ) * 4.;
    target .xy *= rot(time);
    target += + forward;
    vec3 cd = normalize(target - cp);
    vec3 cs = normalize(cross(cd,vec3(0.,1.,0.)));
    vec3 cu = normalize(cross(cd,cs));
    
    float fov = .5;
    vec3 rd = normalize(p.x * cs + p.y * cu + cd * fov);
    
    vec2 d = march(cp,rd);
    if(d.x > 0.)
    {
        vec3 pos = d.x * rd + cp;
        vec2 e   = vec2(0.,0.001);
        vec3 N   = -normalize(map(pos).x - vec3(map(pos - e.xyy).x,map(pos - e.yxy).x,map(pos - e.yyx)));
        vec3 sun = normalize(vec3(2.,4.,8.));
        sun.xz *= rot(time);
        col = vec3( 1. ) * pow( 1. - exp( -.0003 * d.x * d.x * d.x ) , 1.1);
        float diff = max(0.,dot(N,sun));
        diff = mix(diff,1.,.1);
        float sp   = max(0.,dot(reflect(sun,N),cd));
        vec3 ocol = vec3(.8);

        if(d.y == 0.)
        {
            ocol = vec3(.5,0.,1.);
            sp = pow(sp,6.) * 10.;
            col = diff * ocol + sp * vec3(1.);
        }
        else if(d.y == 1.)
        {
            ocol =  vec3( 0., 0., 1.);
            sp = pow(sp,2. ) * 10.;
            col = diff * ocol + sp * vec3(1.);
            col += vec3( 1., 0., 1.) * floor( sin( pos.z - time * 2. ) + .01 );
        }
        else if(d.y == 2.)
        {
            
            ocol = vec3( 0.1,0.,0.1);
            sp = pow(sp,2.);
            col = diff * ocol + sp * vec3(1.);
        }

        
        float tt = 1. - exp(d.x * d.x * d.x * d.x * d.x * -.01);
        col = mix(col,bcol,tt);
    }
    vec3 hsv = rgb2hsv(col);
    hsv.y = (sin(hsv.y) + 1.) * .5;
    hsv.x += sin(time / 50.);
    //hsv.z = 1.;
    col = hsv2rgb(hsv);

    glFragColor = vec4(col, 1.0);
}
