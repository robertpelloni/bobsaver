#version 420

// original https://www.shadertoy.com/view/ftl3Rn

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

float scene(vec3 p)
{
    return length(p)-.8;
}

vec3 getNormal(vec3 p)
{
    //Sampling around the point
    vec2 o = vec2(0.01, 0.0);
    float d = scene(p);
    vec3 n = d - vec3(
                    scene(p-o.xyy),
                    scene(p-o.yxy),
                    scene(p-o.yyx));
    return normalize(n);
}

void main(void)
{

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    
    vec3 cam = vec3(0., 0, -3.);
    vec3 dir = normalize(vec3(uv, 1));
    vec3 lightPos = vec3(3., 8., -8.);
    vec3 lightPos2 = vec3(-2, -3, -4.);
    
    cam.z += time*3.;
    cam.yx = rotate(cam.yx, time*.3);
    dir.yx = rotate(dir.yx, time*.3);
    lightPos.yx = rotate(lightPos.yx, time*.3);
    lightPos2.yx = rotate(lightPos2.yx, time*.3);
    
    
    float t = 0.;
    float k = 0.;
    int i;
    vec3 p;
    for(i; i<100; i++)
    {
        p = cam + dir * t;
        p = mod(p, 4.)-2.;
        k = scene(p);
        t += k;
        if(k < 0.001) break;
    }
    
    vec3 h = cam + dir * t;
    h = mod(h, 4.)-2.;
    vec3 n = getNormal(h);
    
    //diffuse light
    vec3 light = normalize(lightPos - h);
    vec3 diffuse_color = vec3(0.788, 0.666, 0.133);
    diffuse_color = dot(h, light) * diffuse_color;
    
    float shininess = 30.0;
    float specular_intensity = pow(max(dot(n, light), 0.0), shininess);
    vec3 specular_color = vec3( 0.941, 0.662, 0.498); // red
    specular_color = specular_intensity * specular_color;
    
    vec3 light2 = normalize(lightPos2 - h);
    vec3 diffuse_color2 = vec3(0.133, 0.788, 0.737);
    diffuse_color2 = dot(h, light2) * diffuse_color2;
    
    float shininess2 = 100.0;
    float specular_intensity2 = pow(max(dot(n, light2), 0.0), shininess2);
    vec3 specular_color2 = vec3(0.133, 0.788, 0.737); // red
    specular_color2 = specular_intensity2 * specular_color2;
    
    float fog = 1. - (float(i)/100.);

    
    glFragColor.rgb = ((diffuse_color + specular_color) + (diffuse_color2 + specular_color2)/2.) * fog;
}
