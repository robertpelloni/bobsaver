#version 420

// original https://www.shadertoy.com/view/llSfDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Original shader by FabriceNeyret2: https://www.shadertoy.com/view/ltyXWR

// using the base ray-marcher of Trisomie21: https://www.shadertoy.com/view/4tfGRB#

#define r(v,t) { float a = (t)*T, c=cos(a),s=sin(a); v*=mat2(c,s,-s,c); }

#define iRes (resolution.xy)
//#define mouse*resolution.xy (mouse*resolution.xy.xy)
#define time (time/2.)
#define mouse*resolution.xyDown (mouse*resolution.xy.z>0.)

float scene(in vec3 t, out float closest) {
    vec3 ta;
    float x=1e9;

    #define mod4(t)         ( mod(t+2.,4.)-2. )
    #define setbox(t,h,w,d)  abs(t)/vec3(h,w,d)
    #define dbox(t,r)       ( max(t.x,max(t.y,t.z)) -(r) )
    #define dsphere(t,r)    ( length((t).xyz) -(r) )
    #define dcyl(t,r)       ( length((t).xy) -(r) )
    #define union(a,b)       min(a,b)
    #define sub(a,b)         max(a,-(b))

    vec3 b = t;
    t/=dot(t,t);
    //t.xy+= vec2(sin(t.z));
    

    //t-=vec3(time/5.);
    t.x -= time/2.;
    //t.y -= time/3.;

    ta.xy = floor( (t.xy+2.)/4. );
    t.z -= time * sign( mod(ta.x+ta.y,2.) - .5);

    ta = setbox(mod4(t),1,3,16);
    x = dcyl(ta,.5);

    ta = setbox(mod4(t),3,1,16);
    x = union(x, dcyl(ta,.5) );

    ta = setbox(mod4(t+vec3( 0,0,2)), 6,2,1);
    x = sub(x,  dbox(ta,.27) );

    ta = setbox(mod4(t-vec3(.8,0,0)),.6,3,2);
    x = sub(x,  dbox(ta,.5) );

    ta = setbox(mod4(t+vec3(.8,0,0)),.6,3,2);
    x = sub(x,  dbox(ta,.5) );

    ta = setbox(mod4(t               ),1,3,.5);
    x = sub(x,  dbox(ta,.55) );

    ta = setbox(mod4(t-vec3(0,.8,2)),3,.6,2);
    x = sub(x,  dbox(ta,.5) );

    ta = setbox(mod4(t+vec3(0,.8,2)),3,.6,2);
    x = sub(x,  dbox(ta,.5) );

    ta = setbox(mod4(t-vec3( 0,0,1)),10,10,1);
    x = sub(x,  dbox(ta,.12) );

    ta = setbox(mod4(t+vec3( 0,0,1)),10,10,1);
    x = sub(x,  dbox(ta,.12) );

    // float x1 = dsphere(mod4(t),.3);
    // closest = min(closest, x1);

    return x;
}

float scene(in vec3 t) {
    float x;
    return scene(t,x);
}

vec3 g(vec3 t, float d) {
    vec2 e = vec2(0,.001);
    return normalize(vec3(scene(t+e.yxx), scene(t+e.xyx), scene(t+e.xxy)) - vec3(d));
}

void main(void) { //WARNING - variables void (out vec4 f, in vec2 gl_FragCoord) { need changing to glFragColor and gl_FragCoord
    vec4 f = glFragColor;
    f -= f;

    vec2 m;
    //if (mouse*resolution.xyDown)
    //    m = mouse*resolution.xy.xy/iRes*.5;
    //if (m.x < .15) m.x=.15;
    m.y = -m.y*.6+.12;
 // m.y += .1;
    m.x += .5;
    m = (-m+.5);
    
    vec2 uv = gl_FragCoord.xy/iRes*2.-1.;
    uv.y *= iRes.y/iRes.x;
    vec3 ro = vec3(m.x-.1,m.y,.1);
    vec3 ta = vec3(0);
    vec3 cu = normalize(ta-ro);
    vec3 cv = (cross(vec3(0,0,1), cu));
    vec3 cw = (cross(cv, cu));
    vec3 rd = (cu + cv*uv.x + cw*uv.y);

    float decay = 1.;
      int iter = 0;
    float closest = 100000.;
    vec3 p = ro;
    for (float i=1.; i>0.; i-=.005)  {
        float dist = scene(p, closest);
        if(dist<.01) {
            f += decay*vec4(pow(i,2.))*.5;
            f += pow(decay,3.)*vec4(1., .4, .4,1)/dot(p,p)/90.;
            decay /= 2.;
            iter += 1;
            if (iter == 2)
                    break;
            vec3 n = g(p,dist);
            rd = normalize(reflect(rd, n));
            p+=.1*n;
        }
        p += rd*dist*.02;
    }
    f += vec4(0,0,.3,0) * exp(-length(p))*(.5+.5*cos(time/2.)); // glow2 - thanks kuvkar !
    glFragColor = f;
}
