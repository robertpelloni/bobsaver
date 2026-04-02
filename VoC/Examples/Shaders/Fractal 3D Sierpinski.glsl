#version 420

// original https://www.shadertoy.com/view/Xd2XDW

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float DE(vec3 p, float pixsize) {
    const vec3 p0 = vec3(-1,-1,-1);
    const vec3 p1 = vec3(1,1,-1);
    const vec3 p2 = vec3(1,-1,1);
    const vec3 p3 = vec3(-1,1,1);

    const int maxit = 15;
    const float scale = 2.;
    for (int i = 0; i < maxit; ++i) {
        float d = distance(p, p0);
        vec3 c = p0;
        
        float t = distance(p, p1);
        if (t < d) {
            d = t;
            c = p1;
        }
        
        t = distance(p, p2);
        if (t < d) {
            d = t;
            c = p2;
        }
        
        t = distance(p, p3);
        if (t < d) {
            d = t;
            c = p3;
        }
        
        p = (p-c)*scale;
    }
    
    return length(p) * pow(scale, float(-maxit))
        - pixsize; // let the leaves be one pixel in size
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    // vec2 mouse2 = mouse.xy / resolution.xy;
    vec2 mouse=vec2(0.0,0.0);
    float unit_pixsize = 1./(resolution.x+resolution.y);
    
    // camera parameters
    vec3 origin = vec3(-4,mouse*2.-1.);
    vec3 direction = normalize(vec3(1, uv*2.-1.));
    
    float ang1 = sin(time*0.9+42.)*2.+42.;
    float ang2 = sin(time*1.1)*3.;
    
    mat3 rotation1 = mat3(
        1,0,0,
        0,cos(ang1),-sin(ang1),
        0,sin(ang1),cos(ang1)
    );
    mat3 rotation2 = mat3(
        cos(ang2),0,-sin(ang2),
        0,1,0,
        sin(ang2),0,cos(ang2)
    );
    mat3 rotation = rotation1 * rotation2;
    
    const float diameter = 100.;
    const int maxit = 40;
    const float eps = 1e-5;
    
    vec3 p = origin;
    int it = maxit;
    for (int i = 1; i <= maxit; ++i) {
        if (dot(p, p) > diameter) {
            it = i;
            break;
        }
        float d = DE(rotation * p, unit_pixsize * distance(p, origin));
        if (d < eps) {
            it = i;
            break;
        }
        p += direction * d;
    }

    if (it == 0)
        glFragColor = vec4(.5, .5, .9, 1.0);
    else {
        float t = 1. - float(it) / float(maxit);
        glFragColor = vec4(t,t,t,1.0);
    }
}
