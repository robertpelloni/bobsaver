#version 420

// original https://www.shadertoy.com/view/NdVXDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
float pi = acos(-1.);
vec3 ppp;
vec2 map(vec3 p)
{
    float o = 10.;
    float id = 0.;
    vec3 op = p;
    p.xz *= rot(sin(p.y/4.));
    p.xz = abs(p.xz)-3.1;
    p.xz *= rot(p.y/2.);
    p.xz = abs(p.xz)-1.;
    p.xz *= rot(sin(p.y));
    vec3 pp = p;
    p.xz *= rot(p.y * pi/3. + time);
    p.y = sin(p.y * pi/3. + time);
    o = length(vec2(length(p.xy)-1.,p.z))-.3;
     pp.z += sin(pp.y * pi/3. + time)*1.;
    ppp = pp;
    //o = min(o,length(pp.xz)-.6);
    float r = sin(time + pp.y/3.) * .5 + .5;
    float d = length(pp.xz)-r*.7;
    if(o > d)
    {
        o = d;
        id = 1.;
        ppp = pp;
    }
    
    o = mix(max(length(op)-6.,o),o,.9);
    //o = (length(op)-3.)/o;
    o/=1.7;
    
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
        if(depth > 30.)break;
        depth += d.x;
    }
    return vec2(-depth , 0.);

}
float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}
void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 cp = vec3(0.,0.,-28.);
    vec3 target = vec3(0.);
    
    
    //cp.xz *= rot(time + p.y * 12.);
    //target.x += sin(time);
    vec3 col = vec3(.0);
    
    vec3 cd = normalize(vec3(target - cp));
    vec3 cs = normalize(cross(cd , vec3(0.,1.,0.)));
    vec3 cu = normalize(cross(cd,cs));
    
    float fov = 2.5;
    
    vec3 rd = normalize(cd * fov + cs * p.x + cu * p.y);
    
    vec2 d = march(cp,rd);
    if( d.x > 0.)
    {
        vec2 e = vec2(1.0, -1.0) * .01;
        vec3 pos = cp + rd * d.x;
        vec3 N = normalize(
                  e.xyy * map(pos + e.xyy).x +
                  e.yyx * map(pos + e.yyx).x +
                  e.yxy * map(pos + e.yxy).x +
                  e.xxx * map(pos + e.xxx).x);
        vec3 sun = normalize(vec3(2.,4.,8.));
        //sun.xz *= rot(time);
        float diff = max(0.,dot(-sun,N));
        diff = mix(diff , 1.,.1);
        float sp = max(0.,dot(rd,reflect(N,sun)));
        sp = pow(sp,33.6) * 10.;
        float rim = pow(clamp(1. - dot(N, -rd), 0., 1.), 8.) * 3.;
        vec3 mat = mix(vec3(1.),vec3(1.,0.1,0.1),d.y);
        mat -= exp(sin(ppp*2.)) * d.y;
        float up = max(dot(N,vec3(0.,-1.,0.)),0.);
        float down = max(dot(N,vec3(0.,1.,0.)),0.);
        
        col = sp * mat + diff * mat;
        col += up * vec3(.1) + down * vec3(0.,0.,1.);
        
        col -= d.y * mat ;
        col = floor(col * 3.)/3.;
        col *= vec3(1.) * sin(pos * (60. + step(.9,sin(p.y+time))*30.) ) * max(col.r,max(col.g,col.b));
        col -= rim *10.;
        col *= 10.;
    }
    //col.r = atan(col.r,col.g)/pi;
    glFragColor = vec4(col, 1.0);
}
