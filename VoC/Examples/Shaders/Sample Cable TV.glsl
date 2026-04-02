#version 420

// original https://neort.io/art/bvqmj443p9f30ks56qs0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float iteration = 0.;
float pi = acos(-1.);

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}

float map(vec3 p)
{
   
    p.z += sin(time)* .5;
    p.xz*= rot(p.z/10. * (sin(p.z/10. + time/10.)));
    
    p.xy*= rot(p.z/6. * sin(p.z/15. + time/2. + p.x) );
    p.xy += vec2(pi)/2.; 
    p.yz *= rot(sin(time/1.)/6.);
    p.z += time;
    // p.x += 1.;
    p = sin(p) * 2.;
    p = abs(abs(p) - .5) - .01;
    p = clamp(p,vec3(0.),vec3(1.));
    p.z = clamp(p.z , .1,.3);
   // if(p.x > p.y){p.xy = p.yx;}
    if(p.z > p.x){p.xz = p.zx;}
    float o = length(p) - 1.;
    if( o < 1.)
    {
        o -= sin(p.x * 10.)/20.;
        o -= cos(p.y * 10.)/20.;
        o += abs(sin(p.z * 5.)/25.);
    }
    //o = min(o,.5);
    o *= .5;
    return o;
}

float march(vec3 cp,vec3 rd)
{
    float depth = 0.;
    for(int i = 0; i < 198 ;i++)
    {
        vec3 rp = cp + rd * depth;
        float d = map(rp);
        if((d) < 0.01)
        {
            iteration = float(i);
            return depth;
        }
        depth += d;
    }
    depth *= -1.;
    return depth;
    
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0.);
    
    vec3 forward = vec3(0.,0.,0);
    vec3 cp = vec3(0.,0.,-3.) + forward;
   // cp.x += sin(time) * 1.;
    vec3 target = vec3(0.) + forward;
    vec3 cd = normalize(target - cp);
    vec3 cu = normalize(cross(cd,vec3(0.,1.,0.)));
    vec3 cs = normalize(cross(cd,cu));
    
    float fov = mix(1.5 - dot(p,p),1. , abs(sin(time/10.))) ; 
    vec3 rd = normalize(cd* fov + cs * p.x + cu * p.y);
    float d = march(cp,rd);
    if(d > 0.)
    {
        vec2 e = vec2(0.,0.01);
        vec3 pos = d * rd + cp;
        vec3 N = -normalize(map(pos) - vec3(map(pos - e.xyy),map(pos - e.yxy),map(pos - e.yyx)));
        col = vec3(1.)/iteration;
        col = N;
        vec3 sun = normalize(vec3(2.,4.,8.));
        float diff = max(dot(sun,N),0.);
        col = diff * vec3(.8,.3,.6);
        float sp = max(0.,dot(reflect(sun , N),cd ) );
        col = diff * vec3(.1,.1,.1) + pow(sp,24.) * vec3(1.);
       // float shadow = step(march(pos + N * 0.02,N),0.);
        
        //col += vec3(1.,0.,0.) * max(floor( sin(d - time * 4.) + .1),0.);
        col += max(floor( sin(d - time * vec3(4.,8.,8.)/2.)-.6 + .61),0.);
       // col *= shadow;
        float dd =1. - exp(d * d * d * -.0015);
        col = mix(col,vec3(1.,1.,1.),dd);
    }
    glFragColor = vec4(col, 1.0);
}
