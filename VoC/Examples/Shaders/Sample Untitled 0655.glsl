#version 420

// original https://www.shadertoy.com/view/sscSR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
float menger(vec3 p,vec3 offset)
{
    float scale = 1.8;
    vec4 z = vec4(p,1.);
    for(int i = 0;i < 3;i++)
    {
        //z.yz *= rot(float(i) * 2.);
        z = abs(z);  
        //if(z.x < z.y)z.xy = z.yx;
        if(z.x < z.z)z.xz = z.zx;
        if(z.y < z.z)z.yz = z.zy;
        z *= scale;  
        z.xyz -= offset * (scale - 1.);
        if(z.z < -.5 * offset.z * (scale - 1.) )
            z.z += offset.z * (scale - 1.);
    }
    return (length(max(abs(z.xyz) - vec3(1.0, 1.0, 1.0), 0.0))) / z.w;
}
float pi = acos(-1.);
vec3 pp;
vec2 map(vec3 p)
{
    float o = 10.;
    float id = 0.;
    
    //p.xy = sin(p.xy);
    vec3 shift = vec3(2.5,6.5,3.2);
    // float t = floor(iTIme)+pow(fract(iTIme),4.);
    // shift.xy *= rot(t * pi/5. );
    // shift.xy = sin(shift.xy)+1.3;
    o = menger(p,shift);
    pp = p;
    return vec2(o,id);
}

vec2 march(vec3 cp , vec3 rd)
{
    float depth = 0.;
    for(int i = 0 ; i< 99 ; i++)
    {
        vec3 rp = cp + rd * depth;
        vec2 d = map(rp);
        if(abs(d.x) < 0.01)
        {
            return vec2(depth,d.y);
        }
        depth += d.x;
    }
    return vec2(-depth , 0.);

}

vec2 random22(vec2 st)
{
    st = vec2(dot(st, vec2(127.1, 311.7)),
                dot(st, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

vec3 celler2D(vec2 i,vec2 sepc)
{
    vec2 sep = i * sepc;
    vec2 fp = floor(sep);
    vec2 sp = fract(sep);
    float dist = 5.;
    vec2 ouv = vec2(0.);
    vec2 mp = vec2(0.);
    float t = floor(time/3.) + pow(fract(time/3.),3.);
        for (int y = -1; y <= 1; y++)
        {
            for (int x = -1; x <= 1; x++)
            {
                vec2 neighbor = vec2(x, y );
                vec2 rpos = vec2(random22(fp+neighbor));
                vec2 pos = sin( (rpos*6. +t * pi * 1.3) )* 0.5 + 0.5;
                float divs = length(neighbor + pos - sp);
                if(dist > divs)
                {
                    ouv = rpos + neighbor + fp;
                    mp = pos;
                    dist = divs;
                }
            }
    }
    return vec3(ouv,dist);
}

float getEdge(vec2 p,vec2 s)
{
    vec3 e = vec3(1.0, -1.0,0.) * 0.01;
    vec2 edge = celler2D(p + e.xy,s).xy +
                 celler2D(p + e.yx,s).xy -
                 celler2D(p + e.xx,s).xy -
                 celler2D(p + e.yy,s).xy +
                celler2D(p + e.zx,s).xy -
                celler2D(p + e.zy,s).xy +
                celler2D(p + e.xz,s).xy -
                celler2D(p + e.yz,s).xy;
    edge = abs(edge);
    return step(max(edge.x,edge.y),0.);
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    float fn = .2;
    vec3 cell = celler2D(p,vec2(fn));
    //cell = celler2D(cell.xy * p,vec2(3.))/3.;
    vec3 cp = vec3(0.,0.,-6.);
    cp -= cell;
    cp.xz *= rot(time/12.);
    vec3 target = vec3(0.);
    float t = clamp(sin(time+ cell.x/2.),-0.5,.5) + .5;
    t = .3;
    cell.z = mix(cell.z,-1.,1.);
    target = mix(target,cell * 10.,t);
    
    vec3 col = vec3(1.);
    
    vec3 cd = normalize(vec3(target - cp));
    vec3 cs = normalize(cross(cd , vec3(0.,1.,0.)));
    vec3 cu = normalize(cross(cd,cs));
    
    float fov = 2.5;
    
    vec3 rd = normalize(cd * fov + cs * p.x + cu * p.y);
    
    vec2 d = march(cp,rd);
    if( d.x > 0.)
    {
        vec2 e = vec2(1.0, -1.0) * 0.005;
        vec3 pos = cp + rd * d.x;
        vec3 N = normalize(
                  e.xyy * map(pos + e.xyy).x +
                  e.yyx * map(pos + e.yyx).x +
                  e.yxy * map(pos + e.yxy).x +
                  e.xxx * map(pos + e.xxx).x);
        vec3 sun = normalize(vec3(2.,4.,8.));
        //sun.xz *= rot(iTIme);
        float diff = max(0.,dot(-sun,N));
        diff = mix(diff , 1.,.1);
        float sp = max(0.,dot(rd,reflect(N,sun)));
        sp = pow(sp,56.6) * 1.;
        float rim = pow(clamp(1. - dot(N, -rd), 0., 1.), 12.)/.1;
        vec3 mat = vec3(0.);
        mat.r = 0.;
        col = sp * mat + diff * mat + rim;
    }
   // col.rg += cell.rg;
    col *= 1. - cell.z;
    col *= getEdge(p,vec2(fn));
    
    glFragColor = vec4(col, 1.0);
}
