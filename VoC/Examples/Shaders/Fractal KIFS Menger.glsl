#version 420

// original https://www.shadertoy.com/view/ltS3W3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// http://www.fractalforums.com/movies-showcase-%28rate-my-movie%29/very-rare-deep-sea-fractal-creature/

const int Iterations=6;
const float detail=.005;
const vec3 lightdir=-vec3(0.5,1.,0.5);

mat2 rot;

float de(vec3 p); 
vec4 getColour(vec3 p);
vec4 lerp(vec4 col1, vec4 col2, float amt);

vec3 normal(vec3 p) {
    vec3 e = vec3(0.0,detail,0.0);
    
    return normalize(vec3(
            de(p+e.yxx)-de(p-e.yxx),
            de(p+e.xyx)-de(p-e.xyx),
            de(p+e.xxy)-de(p-e.xxy)
            )
        );    
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<48; i++ )
    {
        float h = de(ro + rd*t);
        h = max( h, 0.0 );
        res = min( res, k*h/t );
        t += clamp( h, 0.01, 0.5 );
    }
    return clamp(res,0.0,1.0);
}

vec4 light(in vec3 p, in vec3 dir,float d)
{
    vec4 lightCol;
    vec3 ldir=normalize(lightdir);
    vec3 n=normal(p);
    float sh=softshadow(p,-ldir,1.,20.);
    float diff=max(0.,dot(ldir,-n));
    vec3 r = reflect(ldir,n);
    float spec=max(0.,dot(dir,-r));
    vec3 ray = .8*d*((0.4*p-3.*r)+d*vec3(1.0,0.95,0.85));
//    lightCol = texture2D(iChannel0,ray.xz+ray.xy);
    lightCol = getColour(p);
    return 3.0*lightCol*diff*sh+pow(spec,30.)*.5*sh+.15*max(0.,dot(normalize(dir),-n));    
        }

vec4 raymarch(in vec3 from, in vec3 dir)
{
    float st,d=1.0,totdist=st=0.;
    vec3 p;
    vec4 col;
    float mind=100.;
    for (int i=0; i<90; i++) 
    {
        if (d>detail && totdist<150.)
        {
            p=from+totdist*dir;
            d=de(p);
            mind = min(d, mind);
            totdist+=d;
        }
    }
    vec4 backg=lerp(vec4(1.0,0.9,0.7,1),vec4(0.2,0.4,0.5,1),1.-mind);
    if (d<detail) {
        col=light(p, dir,d); 
    } else { 
        col=backg;
    }
    col = col;//mix(col, backg, 1.0-exp(-.000025*pow(totdist,3.5)));
    return col;
}

void main(void)
{
    float t=time*.3;
    vec2 uv = gl_FragCoord.xy / resolution.xy*2.-1.;
    uv.y*=resolution.y/resolution.x;

    vec3 from=vec3(10.*cos(time*0.3),-.7,5.*sin(time*0.3));
    vec3 to = normalize(vec3(0.,0.,0.) - from);
    vec3 dir=normalize(vec3(uv*.7,1.));
    vec3 up = vec3(0.,1.,0.);
    vec3 right = normalize(cross(to, up));
    up = normalize(cross(right, to));
    mat3 rot3 = mat3(right.x,right.y,right.z,up.x,up.y,up.z,to.x,to.y,to.z);
    dir *= rot3;

    vec4 col=raymarch(from,dir); 
    glFragColor = col;
}

mat3 MakeRPY(float roll, float pitch, float yaw)
{
    float cp = cos(pitch);
    float sp = sin(pitch);
    float sr = sin(roll);
    float cr = cos(roll);
    float sy = sin(yaw);
    float cy = cos(yaw);

    return mat3(cp * cy, (sr * sp * cy) - (cr * sy), (cr * sp * cy) + (sr * sy),
                cp * sy, (sr * sp * sy) + (cr * cy), (cr * sp * sy) - (sr * cy),
                -sp, sr * cp, cr * cp);
}

float de(vec3 p) {
    vec3 rotAxis = vec3(0,1,0);
//    mat3 rot = rotationMatrix3(rotAxis, time*5.);
    p*=vec3(0.4,0.4,0.4);
    vec3 offset = vec3(1,1,1);
    float scale = 3. + 0.3 * sin(time * 0.084);
    float rotx = 5.0 * sin(time * 0.01);
    float roty = 5.0 * sin(time * 0.0057);
    float rotz = 5.0 * sin(time * 0.0266);
    mat3 rot = MakeRPY(rotx,roty,rotz);

    for (int i=0; i<Iterations; i++) {
        p*=rot;
        float tmp;
        
        p = abs(p);
        if (p.x-p.y<0.) {tmp=p.y;p.y=p.x;p.x=tmp;}
        if (p.x-p.z<0.) {tmp=p.z;p.z=p.x;p.x=tmp;}
        if (p.y-p.z<0.) {tmp=p.z;p.z=p.y;p.y=tmp;}

        p.z -= 0.5*offset.z*(scale-1.)/scale;
        p.z = -abs(-p.z);
        p.z += 0.5*offset.z*(scale-1.)/scale;

        p.xy = scale*p.xy - offset.xy*(scale-1.);
        p.z = scale*p.z;
    }
    vec3 d = abs(p) - vec3(1.,1.,1.);
    float distance = min(max(d.x, max(d.y, d.z)),0.) + length(vec3(max(d.x,0.),max(d.y,0.), max(d.z,0.)));
    distance *= pow(scale, -float(Iterations));
    return distance;
}

vec4 lerp(vec4 col1, vec4 col2, float amt)
{
    amt = clamp(amt,0.,1.);
    return col1*amt + col2*(1.-amt);
}

vec4 getColour(vec3 p) {
    p*=vec3(0.4,0.4,0.4);
    vec3 offset = vec3(1,1,1);
    float scale = 3. + 0.3 * sin(time * 0.084);
    float rotx = 5.0 * sin(time * 0.01);
    float roty = 5.0 * sin(time * 0.0057);
    float rotz = 5.0 * sin(time * 0.0266);
    mat3 rot = MakeRPY(rotx,roty,rotz);

    float colour=1000000.;

    for (int i=0; i<Iterations; i++) {
        p*=rot;
        float tmp;
        
        p = abs(p);
        if (p.x-p.y<0.) {tmp=p.y;p.y=p.x;p.x=tmp;}
        if (p.x-p.z<0.) {tmp=p.z;p.z=p.x;p.x=tmp;}
        if (p.y-p.z<0.) {tmp=p.z;p.z=p.y;p.y=tmp;}

        p.z -= 0.5*offset.z*(scale-1.)/scale;
        p.z = -abs(-p.z);
        p.z += 0.5*offset.z*(scale-1.)/scale;

        p.xy = scale*p.xy - offset.xy*(scale-1.);
        p.z = scale*p.z;

        colour = min(colour, length(p)-0.7);
    }
    
    return lerp(vec4(0.21,0.35,0.66,1.), vec4(0.76,0.65,0.21,1.), colour);
}
