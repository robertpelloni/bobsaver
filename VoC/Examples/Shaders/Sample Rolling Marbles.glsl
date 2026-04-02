#version 420

// original https://www.shadertoy.com/view/ltXSWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int maxSteps = 80;
const int reflectionSteps = 5;

const vec4 lightColor = vec4(1.0,.75,0.6,0.0); 
const vec4 lightColor2 = vec4(0.0,1.0,0.6,0.0);
const vec4 lightColor3 = vec4(0.75,0.0,1.0,0.0);

vec3 rayVector(in vec3 position, in vec3 target, in vec2 Coord)
{
    vec3 eye = normalize(target - position);
    vec3 up = vec3(0., 1., 0.);
    vec3 right = cross(eye, up);
    up = cross(eye,right);

    mat3 cameraMatrix = mat3(right.x, up.x, eye.x,
                             right.y, up.y, eye.y,
                             right.z, up.z, eye.z);

    vec2 uv = Coord.xy / resolution.xy - vec2(.5);
    uv.x = uv.x * resolution.x/resolution.y;
    uv.y = -uv.y;
    float focalDistance = 0.6 + .3 * sin(time* .25);
    return (normalize(vec3(uv.x,uv.y,focalDistance)) * cameraMatrix) * .5;
}

vec4 textureBall (in vec2 pos)
{
    return vec4(step(.5,fract((pos.x+pos.y)*4.)));
}

vec4 texturePlane (in vec2 pos)
{
    return vec4(abs(step(0.5,fract(pos.x*3.)) - step(0.5,fract(pos.y*3.))));
}

vec4 shade(in vec3 pos, in vec3 normal, in vec3 cameraVector, in vec3 lightPos, in vec4 lightColor, in vec4 surface)
{
    vec3 light = normalize(lightPos - pos);
    float dotlight = dot(normal,light);

    vec3 cameraReflected = normalize(reflect(cameraVector,normal));
    float spec = 0.0;
    if (dot(cameraReflected,light) < 0.0)
        spec = min(1.0,pow(dot(cameraReflected,light),2.0));
    return (surface
        * vec4(0.2+dotlight) * lightColor
        + vec4(0.5*spec)) * 10.0/length(lightPos - pos); // Sphere color
}

float map(in vec3 p, in vec3 shapeLoc, out vec3 pm)    
{
    float bounce = 1.6*abs(sin(time + float(int(p.y/6.0) + int(p.x/6.0))));
    pm = vec3(mod(p.x,6.0),p.y-bounce,mod(p.z,6.0)) - shapeLoc;
    
    return min(length(pm) - 1.8, p.y); 
}
    
vec3 normal(in vec3 p, in vec3 pm)
{
    if (p.y < 0.1)
    {
        return vec3(0.,1.,0.);
    }
    else
    {
        return normalize(pm);
    }
}

vec4 texture(in vec3 p, in vec3 pm, in mat3 rotation)
{
    if (p.y < 0.1)
    {
        return texturePlane( vec2(p.x *.1 - 3.1415 * .5 * time,p.z *.1));
    }
    else
    {
        vec3 pmr = rotation * pm; 
        return textureBall( vec2(atan(pmr.x,pmr.z)*.20,pmr.y*.25));
    }
}

vec4 reflection(in vec3 ro, in vec3 rd, in vec3 shapeLoc, in mat3 rotation, in vec3 lights[3])
{
    vec4 color = vec4(0.0);

    float t = 1.6;
    for(int i = 0; i < reflectionSteps; ++i)
    {
        vec3 p = ro + rd * t;
        
        vec3 pm = vec3(0.,0.,0.);
        float d = map(p, shapeLoc, pm);
        if(d < 0.1)
        {
            vec3 normal = normal(p, pm); vec4 texc = texture(p, pm, rotation);

            color = (shade(p, normal, -rd, lights[0], lightColor, texc)
                + shade(p, normal, -rd, lights[1], lightColor2, texc)
                + shade(p, normal, -rd, lights[2], lightColor3, texc)) * .3333;
            break;
        }

        t += d;
    }

    return color;
}

vec4 march(in vec3 ro, in vec3 rd, in vec3 shapeLoc, in mat3 rotation, in vec3 lights[3])
{
    vec4 color = vec4(0.0);

    float t = 0.0;
    for(int i = 0; i < maxSteps; ++i)
    {
        vec3 p = ro + rd * t;

        vec3 pm = vec3(0.,0.,0.);
        float d = map(p, shapeLoc, pm);
        if(d < 0.01)
        {
            vec3 normal = normal(p, pm); vec4 texc = texture(p, pm, rotation);

            vec3 cameraReflected = normalize(reflect(rd, -normal));

            color = (shade(p, normal, -rd, lights[0], lightColor, texc)
                + shade(p, normal, -rd, lights[1], lightColor2, texc)
                + shade(p, normal, -rd, lights[2], lightColor3, texc)) * .333
                + 0.5*reflection(p, cameraReflected, shapeLoc, rotation, lights);
                ;
            break;
        }

        t += d;
    }
    return color;
}

void main(void)
{
    vec3 shapeLoc = vec3(3.0,1.8,3.0);
    vec3 cameraLoc = vec3(4.0 * sin(time), 6.0 + 4.0 * sin(0.4*time) , 4.0 * cos(time)) + shapeLoc;
    vec3 cameraTarget = shapeLoc;
    vec3 lights[3];
    lights[0] = vec3(3. + 4.0 * sin(time*2.), 8.0 + 8.0 * sin(0.4*time) , 3.+4.0 * cos(2.*time));
    lights[1] = vec3(3. + 4.0 * sin(time*3.), 4.0 + 4.0 * sin(0.2*time) , 3.+8.0 * cos(3.*time));
    lights[2] = vec3(3. + 8.0 * sin(time*4.), 4.0 + 4.0 * sin(0.1*time) , 3.+4.0 * cos(4.*time));
    
    vec3 ro = cameraLoc;
    vec3 rd = rayVector(cameraLoc, cameraTarget, gl_FragCoord.xy);

    mat3 rotation = mat3(cos(time*5.),-sin(time*5.), 0.,
                  sin(time*5.),cos(time*5.), 0.,
                   0.,0.,1.);

    
    glFragColor = march(ro, rd, shapeLoc, rotation, lights);
}
