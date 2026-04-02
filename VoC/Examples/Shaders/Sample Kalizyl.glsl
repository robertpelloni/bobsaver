#version 420

// original https://www.shadertoy.com/view/XtlGDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*    kalizyl 
    
    (c) 2015, stefan berke (aGPL3)

    Another attempt on the kali set
    http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/

    Looks cool and frametime is not too bad -
    but still uses precission 0.1 for raymarching. 
    Maybe saves some speed by not coloring the surface.
    
*/

#define NUM_TRACE         80
#define FOG_DIST         5.
#define KALI_PARAM         vec3(0.71)
#define CYL_RADIUS         0.07
#define LIGHT_COL         vec3(1.0, 0.8, 0.4)
#define FOG_COL         vec3(0.5, 0.7, 1.0)

// standard kali set 
// modified to return distance to cylinders in 'kali-space'
float scene_dist(in vec3 p)
{
    float d = 100.;
    for (int i=0; i<4; ++i)
    {
        p = abs(p) / dot(p, p) - KALI_PARAM;
        d = min(d, length(p.xz) - CYL_RADIUS);
    }
    return d;
}

// returns distance to spheres
float light_dist(in vec3 p)
{
    float d = 100.;
    for (int i=0; i<3; ++i)
    {
        p = abs(p) / dot(p, p) - KALI_PARAM;
        vec3 lightpos = vec3(0., 1.+sin(time+p.y+float(i)*1.3), 0.);
        d = min(d, length(p - lightpos) - CYL_RADIUS);
    }
    return d;
}

vec3 traceRay(in vec3 pos, in vec3 dir)
{
    vec3 p = pos;

    float t = 0., 
          d = scene_dist(pos), 
          mlightd = 100.;

    for (int i=0; i<NUM_TRACE; ++i)
    {    
        if (d < 0.001 || t >= FOG_DIST) 
            continue;

        p = pos + t * dir;
        d = scene_dist(p);

        // distance to light
        mlightd = min(mlightd, light_dist(p));

        // ahh, precission is a big matter again
        t += d * 0.1;        
    }

    // only fog contribution
    vec3 col = FOG_COL * min(1., t/FOG_DIST);

    // plus light glow
    col += LIGHT_COL / (1. + 50.*max(0., mlightd));

    return col;
}

// camera path
vec3 path(float ti)
{
    float a = ti * 3.14159265 * 2.;

    return vec3(
                1.1 * sin(a),
                0.52 * sin(a*2.),
                1.1 * cos(a) );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2. - 1.;
    uv.x *= resolution.x / resolution.y;
    
    vec3 pos, dir;
    
        // camera time
        float ti = time / 19.;

        pos = path(ti);

        // camera orientation matrix
        vec3 look;

        // how much to look towards the center [0,1]
        float lookcenter = 0.45 + 0.45 * sin(ti*7.);
        look = normalize(path(ti + 0.1) - pos);
        look = look + lookcenter * (normalize(-pos) - look);
        vec3 up = normalize(cross(vec3(0., 1., 0.), look));
        vec3 right = normalize(cross(look, up));
        //look = normalize(cross(up, right));
        mat3 dirm = mat3(right, up, look);

        dir = dirm * normalize(vec3(uv, 1.5));
    glFragColor = vec4( traceRay(pos, dir), 1.);    
}
