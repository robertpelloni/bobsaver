#version 420

//original https://www.shadertoy.com/view/4djGzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct tSphere {
    vec3 center;
    float radius;
    vec3 color;
    float spec;
};

// rotate position around axis
vec2 rotate(vec2 p, float a)
{
    return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}

float intersect(inout vec3 ray, vec3 dir, inout vec3 nml, inout tSphere sphere)
{
    float dist = 100.0;

    sphere.radius = 0.0;
    sphere.center = vec3(0.0);

    float st = sin(time*0.2);
    float ct = cos(time*0.2);
    
    for (float i=0.0; i<5.0; i++) {
        for (float j=0.0; j<5.0; j++) {
            float k = i*5.0 + j;
            
            float dst = abs(sin(i*j+2.0*time*0.01*k)) + 1.0;
            vec3 cen = vec3(st+dst*(i-2.0) + cos(time*0.1+k*4.0)*2.0, 
                            ct+dst*(j-2.0),
                            sin(time*0.1+k*4.0)*2.0);
            cen.xy = rotate(cen.xy, time*0.2);
            cen.xz = rotate(cen.xz, time*0.1);
            cen.z += 3.0;
            float r = 0.3+(1.0-0.3*abs(4.0-(i+j)));
            
            vec3 rc = ray-cen;
            float b = dot(dir, rc);
            float c = dot(rc, rc) - r*r;
            float d = b*b - c;
    
            if (d > 0.0) {
                float t = -b - sqrt(d);
                if (t > 0.0 && t < dist) {
                    dist = t;
                    sphere.radius = r;
                    sphere.center = cen;
                    float odd = mod(k, 2.0);
                    sphere.color = mix(vec3(0.01, 0.01, 0.01), vec3(0.95, 0.81, 0.71), odd);
                    sphere.spec = mix(64.0, 3.0, odd);
                }
            }
        }
    }
    ray += dist*dir;
    nml = normalize(sphere.center - ray);
    return dist;
}

vec3 shade(vec3 ray, vec3 dir, vec3 nml, float dist, tSphere sphere)
{
    vec3 col = vec3(0.0, 0.0, 0.0);

    vec3 lightPos = vec3(cos(time*0.1)*-8.5, sin(time*.03)*1.4+5.0, sin(time*0.1)*4.0-5.4);
    
    vec3 shadow = ray, snml = vec3(0.0);
    tSphere s;
    float sdist = intersect(shadow, normalize(lightPos - shadow), snml, s);

    vec3 light = normalize(lightPos - ray);
    vec3 specCol = normalize(sphere.color);
    if (sphere.radius == 0.0) {
        light = normalize(lightPos);
        sphere.color = vec3(0.75, 0.55, 0.35);
    }
    if (s.radius == 0.0) {
        // lighting
        if (sphere.radius == 0.0) {
            nml = -nml;
            col = vec3(0.75, 0.55, 0.35);
            sphere.spec = 16.0;
            specCol = vec3(0.01);
        } else {
            col = sphere.color;
        }
        float diff = max(0.0, dot(nml, -light));
        vec3 ref = reflect(dir, nml);
        float spec = max(dot(ref, light), 0.0);
        spec = pow(spec, sphere.spec);
        
        col *= diff;
        col += spec * specCol * 2.0;
    }
    col += max(0.0, dot(nml, light)) * sphere.color * 0.1;

    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 2.0 * uv - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 eye = vec3(0.0, 1.0, -5.0);

    vec3 dir = normalize(vec3(uv, 1.0));

    vec3 ray = eye;
    vec3 nml = vec3(0.0);
        
    vec3 col = vec3(0.0, 0.0, 0.0);
    
    tSphere sphere;

    sphere.color=vec3(0.0);
    sphere.spec=0.0;
    
    float dist = intersect(ray, dir, nml, sphere);

    //float fog = clamp(dist / 15.0, 0.0, 1.0);
    //fog *= fog;
    
    float refF = 0.0;
    
    vec3 ref = dir;
    col = shade(ray, ref, nml, dist, sphere);

    if(sphere.radius > 0.0)
    {
        vec3 diff = normalize(sphere.color);
        ref = reflect(ref, nml);
        dist = intersect(ray, ref, nml, sphere);
        col += 0.3 * diff * shade(ray, ref, nml, dist, sphere);

        if(sphere.radius > 0.0)
        {
            diff *= normalize(sphere.color);
            ref = reflect(ref, nml);
            dist = intersect(ray, ref, nml, sphere);
            col += 0.15 * diff * shade(ray, ref, nml, dist, sphere);
        }
    }

    //col = (1.0-fog) * col + fog * vec3(0.9, 0.6, 0.4);
    
    
    // gamma correction
    col = 1.0 - exp(-col * 3.5);
    
    
    glFragColor = vec4(col, 1.0);
}
