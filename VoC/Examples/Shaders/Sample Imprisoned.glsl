#version 420

// original https://www.shadertoy.com/view/wlGSz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float glow = 0.;  //GLOW baby

float sphere(vec3 pos, float radius)
{
    return length(pos) - radius;
}

float box(vec3 pos, vec3 size)
{
    return length(max(abs(pos) - size, 0.0));
}

vec3 twist(vec3 pos)
{
    float c = sin(.1 * pos.x + time * cos(time*.001));
    float s = cos(.1 * pos.x + time * cos(time*.001));
    mat2  m = mat2(c, -s, s, c);
    return vec3(m * pos.zy, pos.x);
}

float unionSDF(float distA, float distB)
{
    return min(distA, distB);
}

float differenceSDF(float distA, float distB)
{
    return max(distA, -distB);
}

float hollowBox(vec3 pos, float radius)
{
    return differenceSDF(box(pos, vec3(radius)), sphere(pos, radius*1.3));
}

float distfunc(vec3 pos, float radius)
{
    float hollowB = hollowBox(twist(pos), radius);
    float sphereB = sphere(pos, radius*0.8);
    float shape = unionSDF(hollowB, sphereB);
    glow += 0.1 / (0.1 + shape*shape);
    return shape;
}

void main(void)
{
    vec3 cameraOrigin = vec3(20. * sin(time*.5), 20. * cos(time*.5), 14.);
    vec3 cameraTarget = vec3(0.0, 0.0, 0.0);
    vec3 upDirection = vec3(0.0, 1.0, 0.0);
    vec3 cameraDir = normalize(cameraTarget - cameraOrigin);
    vec3 cameraRight = normalize(cross(upDirection, cameraOrigin));
    vec3 cameraUp = cross(cameraDir, cameraRight);
    
    vec2 screenPos = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    screenPos.x *= resolution.x / resolution.y;
    
    vec3 rayDir = normalize(cameraRight * screenPos.x + cameraUp * screenPos.y + cameraDir);
    
    const int MAX_ITER = 128;
    const float MAX_DIST = 100.0;
    const float EPSILON = 0.002;

    float totalDist = 0.0;
    vec3 pos = cameraOrigin;
    float dist = EPSILON;
    
    float radius = 10.;

    for (int i = 0; i < MAX_ITER; i++)
    {
        if (dist < EPSILON || totalDist > MAX_DIST)
            break;

        dist = distfunc(pos, radius);
        totalDist += dist;
        pos += dist * rayDir*.5;
    }
    
    if (dist < EPSILON)
    {
        vec2 eps = vec2(0.0, EPSILON);

        vec3 normal = normalize(vec3(
            distfunc(pos + eps.yxx, radius) - distfunc(pos - eps.yxx, radius),
            distfunc(pos + eps.xyx, radius) - distfunc(pos - eps.xyx, radius),
            distfunc(pos + eps.xxy, radius) - distfunc(pos - eps.xxy, radius)));

        float diffuse = max(0.0, dot(-rayDir, normal * 0.9));
        float specular = pow(diffuse, 100.0);
        
        vec3 color = vec3(.2*sin(time*0.2) + 0.45,
                          .2*cos(time*0.3) + 0.45,
                          .2*sin(time*0.7) + 0.45) * (diffuse + specular) / (1. + totalDist * 0.05);

        glFragColor = vec4(color + glow*.015, 1.0);
    }
    else
        glFragColor = vec4(0.) + glow*.02;
}
