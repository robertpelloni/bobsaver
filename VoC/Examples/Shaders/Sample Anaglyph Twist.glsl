#version 420

// original https://www.shadertoy.com/view/wsyfDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Twist3000" by z0rg. https://shadertoy.com/view/tddczf
// 2020-12-02 12:26:20

#define sat(a) clamp(a, 0., 1.)
mat2 r2d(float a){float sa = sin(a);float ca=cos(a);return mat2(ca,sa,-sa,ca);}

float lenny(vec2 p) { return abs(p.x)+abs(p.y); }

vec3 getDir(vec3 fwd, vec2 uv)
{
    vec3 r = normalize(cross(normalize(fwd), vec3(0.,1.,0.)));
    vec3 u = normalize(cross(r, normalize(fwd)));
    float fov = .8;
    return uv.x*r+uv.y*u+fov*fwd;
}

vec2 add(vec2 a, vec2 b)
{
    if (a.x < b.x)
        return a;
    return b;
}

// Credits to IQ
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec2 map(vec3 p)
{
    vec3 p2 = p-vec3(0.,1.,0.);
    p2.xz *= r2d(sin(p.y+time));
    vec2 box = vec2(sdBox(p2, vec3(1., 3., 1.)), 1.);
    vec2 ground = vec2(p.y, 0.); 
    return add(box, ground);
}

// Credits to IQ
vec3 calcNormal( in vec3 p, in float t )
{
    float e = 0.001*t;

    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}
vec3 rdr2(vec2 uv, vec3 ro, vec3 rd)
{
    vec3 grad = (1.-sat(abs(uv.x*1.)))*vec3(0.6, 0.87,1.).zxy;
    vec3 col = grad*.5*(sin(time*.5)*.5+.5);
    col += (1.-pow(sat(lenny(uv)-.2), .5))*.5;
    
    float bps = 1./2.2;
    float beat = mod(time, bps)/bps;
    
    float beat2 = mod(time+1., bps)/bps;
    

    
    float d = 0.01;
    for (int i = 0; i < 128; ++i)
    {
        vec3 p = ro + rd * d;
        vec2 res = map(p);
        if (res.y > 0.5)
        col += pow((1.-sat(res.x*.05)), 5.5)*.03*vec3(0.4,.57,1.);
        if (res.x < 0.01 && d < 100.)
        {
            vec3 norm = calcNormal(p, d);
            vec3 diff = vec3(0.);
            vec3 spec = vec3(0.);//0.3, 0.7,1.);
            if (res.y < 0.5)
            {
                float chkSz = 2.5;
                float sharp = 50.;
                float checkerBoard = mod(p.x*1., chkSz) - .5*chkSz;
                checkerBoard = clamp(checkerBoard*sharp, -1.0, 1.0);
                checkerBoard *= clamp((mod(p.z*1., chkSz) - .5*chkSz)*sharp, -1., 1.);
                
                diff = mix(vec3(0.),vec3(0.7,1.,0.), sat(checkerBoard*1.));
                spec = vec3(1.,.1,0.1).zxy;
            }
            
            spec = spec.zyx;
            
            
            float lSpd = .5;
            vec3 lPos = vec3(0.,1.,0.);
            vec3 lDir = normalize(lPos-p);
            col += vec3(.1); // Ambient
            vec3 h = normalize(lDir+rd);
            col += diff*sat(dot(norm, lDir)); // diffuse
            col += spec*pow(sat(dot(norm,h)), 2.9); // spec
            break;
        }
        d += res.x*.5;
    }
    
    
    col += grad*.2;
    col *= 1.-pow(sat(length(uv*.5)), .5);
    
    col += (1.-pow(sat(lenny(uv*.5)), .5))*.1*sat(d-10.);
    col *= (1.-sat(beat2-.7))*vec3(1.)*(pow(sat(d/100.), .1));

    return col;
}

vec3 rdr(vec2 uv)
{
    float dist = 12.;// +1.5*beat;
    float camT = time*.5;
    
    vec3 ro = vec3(dist*sin(camT),4.+sin(camT),dist*cos(camT));//vec3(sin(time*.5+1.), 1., -5.+mod(time, 30.));
    vec3 target = vec3(0., 2.,0.);
    vec3 rd = getDir(normalize(target-ro),uv); 
    
    vec2 dir = normalize(uv);
    float strength = length(uv)*0.05;
    
    vec3 col;

    
    float deye = 0.3;
    
    ro -= deye*normalize(cross(normalize(target-ro), vec3(0.,1.,0.)));
    float left = rdr2(uv, ro, rd).x;
    
    ro += deye*2.0*normalize(cross(normalize(target-ro), vec3(0.,1.,0.)));
    vec2 right = rdr2(uv, ro, rd).yz;

    col += vec3(left,0.,0.) +vec3(0.,right.xy);
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-vec2(.5)*resolution.xy)/resolution.xx;

    vec3 col;
    
    col = rdr(uv);

    glFragColor = vec4(col,1.0);
}
