#version 420

// original https://www.shadertoy.com/view/llKyRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
    );
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float scene(vec3 p)
{
    vec3 sp = p + vec3(1,3,2);

    return min(
        max(
            max(
                sdBox(p, vec3(1.)),
                -sdBox(p,vec3(.9))
            ),
            abs(mod(length(sp)-time*.2,.2)-.1)-.01
        ),
        length(p)-.8
    );
}

float sceneWithFloor(vec3 p)
{
    return min(
        scene(p),
        1.+p.y
    );
}

vec3 trace(vec3 cam, vec3 dir)
{
    vec3 accum = vec3(1);
       // 20 maybe overkill?
    for (int bounce = 0; bounce < 20; bounce++)
    {
        float tfloor = (cam.y + 1.)/-dir.y;
        float t = 0.;
        float k = 0.;
        for(int i = 0; i < 100; i++)
        {
            k = scene(cam + t * dir);
            t += k;
            if (k < 0.001 || (tfloor > 0. && t > tfloor))
                break;
        }
        if (tfloor > 0.)
            t = min(t, tfloor);

        vec3 h = cam + t * dir;

        vec2 o = vec2(.005, 0);
        vec3 n = normalize(vec3(
            sceneWithFloor(h+o.xyy)-sceneWithFloor(h-o.xyy),
            sceneWithFloor(h+o.yxy)-sceneWithFloor(h-o.yxy),
            sceneWithFloor(h+o.yyx)-sceneWithFloor(h-o.yyx)
        ));

        if (h.y < -.999)
        {
            // floor
            float A = .5;
            float B = max(0.,sceneWithFloor(h+n*A));
            float w = clamp(1.-length(h.xz) * .01, 0., 1.);
            w = w * .2 + .8;
            return accum * vec3(pow(B/A,.7)*.6+.4) * w;
        }
        else if (length(h) < .85)
        {
            // ball
            float fresnel = mix(.001,1.,pow(1.-dot(-dir, n),5.));
            accum *= fresnel;
            cam = h + n * .01;
            dir = reflect(dir, n);
        }
        else if (length(h) < 2.) // ew yucky hack
        {
            // cube
            accum *= vec3(.72,.576,.288);
            cam = h + n * .01;
            dir = reflect(dir, n);
        }
        else
        {
            // sky
            return accum * vec3(.8);
        }
    }
    return vec3(0);
}

void main(void)
{

    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;

    vec3 cam = vec3(0,0,-4);
    vec3 dir = normalize(vec3(uv, 1));

    cam.yz = rotate(cam.yz, sin(time*.1)*.25+.25);
    dir.yz = rotate(dir.yz, sin(time*.1)*.25+.25);

    cam.xz = rotate(cam.xz, time*.3);
    dir.xz = rotate(dir.xz, time*.3);

    glFragColor = vec4(pow(trace(cam,dir),vec3(.45)),1);
}
