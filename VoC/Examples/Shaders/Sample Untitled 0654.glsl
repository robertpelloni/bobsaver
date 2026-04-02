#version 420

// original https://www.shadertoy.com/view/7d3XWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
float bo(vec3 p , vec3 s){p = abs(p) - s;return max(p.x,max(p.y,p.z));}
float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}
vec3 random33(vec3 st)
{
    st = vec3(dot(st,vec3(127.1, 311.7,811.5)),
                dot(st, vec3(269.5, 183.3,211.91)),
                dot(st, vec3(511.3, 631.19,431.81))
                );
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

float norm(vec3 p, float n)
{
    vec3 t=pow(abs(p),vec3(n));
    return pow(t.x+t.y,1./n);
}

vec4 celler3D(vec3 i,vec3 sepc)
{
    float stime = time / 1.5;
    vec3 sep = i * sepc;
    vec3 fp = floor(sep);
    vec3 sp = fract(sep);
    float dist = 5.;
    vec3 mp = vec3(0.);
    vec3 opos = vec3(0.);
    
    for (int z = -1; z <= 1; z++)
    {
        for (int y = -1; y <= 1; y++)
        {
            for (int x = -1; x <= 1; x++)
            {
                vec3 neighbor = vec3(x, y ,z);
                vec3 rpos = vec3(random33(fp+neighbor));
                vec3 pos = sin( (rpos*50. +stime/(230. + 100.*cos(stime/130.) ) ) ) * 0.5 + 0.5;
                float shape = 0.5 + clamp(sin(stime),0.,1.) *30.;
                float divs = length(neighbor + pos - sp);
                
                if(dist > divs)
                {
                    opos = neighbor + fp + rpos;
                    mp   = pos;
                    dist = divs;
                }
            }
        }
    }
    return vec4(opos,dist);
}

vec2 map(vec3 p)
{
    float o = 10.;
    float id = 0.;
    
    o = length(p + vec3(tan(time/5.),sin(time),cos(time))) - .8;
    p.xz *= rot(time);
    p.yz *= rot(time);
    float bb = length(p + vec3(0,cos(time/3.),0)) - 1.;
    bb = mix(bo(p + vec3(0.,sin(time),0.),vec3(1.) ),bb,clamp(sin(time) , -.5,.5) + .5 );
    o = smin(o,bb,3.);
    
    return vec2(o,id);
}

vec2 march(vec3 cp , vec3 rd)
{
    float depth = 0.;
    for(int i = 0 ; i< 66 ; i++)
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

vec3 getNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.005;
    vec3 N = normalize(
              e.xyy * map(pos + e.xyy).x +
              e.yyx * map(pos + e.yyx).x +
              e.yxy * map(pos + e.yxy).x +
              e.xxx * map(pos + e.xxx).x);
    return N;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 cp = vec3(0.,0.,-6.);
    vec3 target = vec3(0.);
    
    vec3 col = vec3(0.);
    
    vec3 cd = normalize(vec3(target - cp));
    vec3 cs = normalize(cross(cd , vec3(0.,1.,0.)));
    vec3 cu = normalize(cross(cd,cs));
    
    float fov = 2.5;
    
    vec3 rd = normalize(cd * fov + cs * p.x + cu * p.y);
    p = vec2(length(p),acos(p));
    //vec4 cells = celler3D(vec3(p * rot(time + p.x),1.).zxy,vec3(2.3));
    vec3 rdd = rd;
    rdd.xz *= rot(time/4.);
    rdd.yz *= rot(time/6.);
    vec4 cells = celler3D(rdd,vec3(3.3));
    col = cells.xyz * (1.-cells.w);
    vec3 bg = col;
    vec2 d = march(cp,rd);
    if( d.x > 0.)
    {
        vec3 pos = cp + rd * d.x;
        vec4 cell = celler3D(pos,vec3(3.));
        cell.xyz /= 3.;
        col = cell.xyz;
        vec3 N = getNormal(cell.xyz);
        
        vec3 sun = normalize(vec3(2.,4.,0.));
        float diff = max(0.,dot(-sun,N));
        diff = mix(diff , 1.,.1);
        float sp = max(0.,dot(rd,reflect(N,sun)));
        sp = pow(sp,16.) * 1.;
        float rim = pow(clamp(1. - dot(N, -rd), 0., 1.), 13.);
        vec3 mat = vec3(0.,1.,1.);
        
        vec4 ref = celler3D(reflect(N,sun),vec3(3.3));
        ref.xyz = ref.xyz * (1.-ref.w);
        
        col = sp * ref.xyz + diff * mat + rim;
        col += cell.xyz/10.;
        col *= max(ref.xyz,0.);
        //col = bg;
    }
    
    glFragColor = vec4(col, 1.0);
}
