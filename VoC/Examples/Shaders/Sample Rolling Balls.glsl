#version 420

// original https://www.shadertoy.com/view/ltVyRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi (acos(-1.))

// I changed the timing slightly for shadertoy so it loops at exactly 5 seconds - I got the math wrong on stream
#define time (time * pi * .4)

vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
    );
}

float sdTorus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

float tick()
{
    float t = sin(time)*.5+.5;
    return t*2.-1.;
}

vec2 halfScene(vec3 p)
{
    p.x = mod(p.x+2., 4.)-2.;
    float env = max(
        max(p.y,-p.z),
        -sdTorus(p, vec2(1,.25))
    );

    p.xz = rotate(p.xz, time);
    p.z -= step(0.,cos(time))*2.-1.; // tweaked this line - sign(x) and step(0,x)*2-1 are not the same when x is zero

    float ball = sdSphere(p,.25);

    return vec2(min(env,ball), env<ball?1:0);
}

vec2 scene(vec3 p)
{
    vec3 pA = p;
    vec3 pB = p;

    pA.x += tick();
    pB.x -= tick();
    pB.z *= -1.;

    vec2 a = halfScene(pA);
    vec2 b = halfScene(pB);
    return vec2(min(a.x,b.x),a.x<b.x?a.y:b.y);
}

vec3 trace(vec3 cam, vec3 dir)
{
    vec3 accum = vec3(1);
    for(int bounce=0;bounce<3;++bounce)
    {
        float t;
        vec2 k;
        for(int i=0;i<100;++i)
        {
            k = scene(cam+dir*t);
            t += k.x;
            if (k.x < .001 || k.x > 10.)
                break;
        }

        // sky hack
        if (k.x > 10.)
            k.y = 2.;

        vec3 h = cam+dir*t;
        vec2 o = vec2(.001, 0);
        vec3 n = normalize(vec3(
            scene(h+o.xyy).x-scene(h-o.xyy).x,
            scene(h+o.yxy).x-scene(h-o.yxy).x,
            scene(h+o.yyx).x-scene(h-o.yyx).x
        ));

        if (k.y == 2.)
        {
            // sky
            // tweaked - I forgot to include the accumulation term on stream
            return vec3(dir.y*.15+.1) * vec3(.5,1,.8) * 30. * accum;
        }
        if (k.y == 1.)
        {
            float A = .1;
            float B = scene(h+n*A).x;
            float fakeAO = clamp(B/A,0.,1.);
            fakeAO = pow(fakeAO,.6)*.2+.8;

            float light = n.y*.5+.5;

            vec3 color = vec3(.3,1,.7)*.8;

            h.x += tick() * sign(h.z);
            if(h.y > -.001)
                color += smoothstep(.071,.07,length(fract(h.xz*4.)-.5));

            // floor
            return light * fakeAO * accum * color;
        }
        else
        {
            // balls
            float fresnel = pow(1.-dot(-dir,n),3.);
            fresnel = mix(.04,1.,fresnel);
            accum *= fresnel;
            cam = h + n*.0015;
            dir = reflect(dir, n);
        }
    }
    return vec3(0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy-.5;
    uv.x *= resolution.x / resolution.y;

    vec3 cam = vec3(uv*4.,-5.);
    vec3 dir = vec3(0,0,1);

    cam.yz = rotate(cam.yz, atan(1.,sqrt(2.)));
    dir.yz = rotate(dir.yz, atan(1.,sqrt(2.)));

    cam.xz = rotate(cam.xz, pi/4.);
    dir.xz = rotate(dir.xz, pi/4.);

    glFragColor = vec4(trace(cam,dir),1.0);
}
