#version 420

// original https://www.shadertoy.com/view/WlfcRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define VERTEXCOUNT 12
#define TRIANGLECOUNT 20
#define PHI 1.618
#define LIGHTDIRECTION normalize(vec3(0, 1., -0.5))
#define LIGHTINTENSITY 0.5
#define AMBIENTLIGHT 0.5

// This array stores the positions of all 12 vertices in the form of vec3
vec3 vertices[VERTEXCOUNT] = vec3[VERTEXCOUNT]
(
    vec3(-1,  PHI, 0),
    vec3( 1,  PHI, 0),
    vec3(-1, -PHI, 0),
    vec3( 1, -PHI, 0),
    
    vec3(0, -1,  PHI),
    vec3(0,  1,  PHI),
    vec3(0, -1, -PHI),
    vec3(0,  1, -PHI),
    
    vec3( PHI, 0, -1),
    vec3( PHI, 0,  1),
    vec3(-PHI, 0, -1),
    vec3(-PHI, 0,  1)
);

// This array stores the indices of three vertices which form a triangle
int triangles[TRIANGLECOUNT * 3] = int[TRIANGLECOUNT * 3]
(
     5, 11,  0,
     1,  5,  0,
     7,  1,  0,
    10,  7,  0,
    11, 10,  0,
    
     9,  5,  1,
     4, 11,  5,
     2, 10, 11,
     6,  7, 10,
     8,  1,  7,
    
     4,  9,  3,
     2,  4,  3,
     6,  2,  3,
     8,  6,  3,
     9,  8,  3,
    
     5,  9,  4,
    11,  4,  2,
    10,  2,  6,
     7,  6,  8,
     1,  8,  9
);

// This array stores the rotated and translated position of the vertices
vec3 vertexbuffer[VERTEXCOUNT];

struct Tri2D
{
    vec2 a;
    vec2 b;
    vec2 c;
};
    
struct Tri3D
{
    vec3 a;
    vec3 b;
    vec3 c;
};

       
// This function rotates a vec2 by 90 degrees around the origin  
vec2 rot90(vec2 vec)
{
    return vec2(vec.y, -vec.x);
}   

// This function returns 1 if the point p lies in the triangle t otherwise 0
float mask(Tri2D t, vec2 p)
{
    float ab = step(0., dot(rot90(t.b-t.a), p-t.a));
    float bc = step(0., dot(rot90(t.c-t.b), p-t.b));
    float ca = step(0., dot(rot90(t.a-t.c), p-t.c));
    return ab * bc * ca;
}

// This function projects a three-dimensional triangle on a two-dimensional plane
Tri2D project(Tri3D t)
{
    vec2 a = vec2(t.a.x/t.a.z, t.a.y/t.a.z);
    vec2 b = vec2(t.b.x/t.b.z, t.b.y/t.b.z);
    vec2 c = vec2(t.c.x/t.c.z, t.c.y/t.c.z);
    return Tri2D(a, b, c);
}

// This function calculates the intensity of light hitting a triangle
float light(Tri3D t3)
{
    vec3 normal = normalize(cross(t3.a - t3.c, t3.b - t3.c));
    return dot(normal, LIGHTDIRECTION) * LIGHTINTENSITY + AMBIENTLIGHT;
}

// This functions rolls a point by an angle a around the origin
vec3 roll(vec3 p, float a)
{
    vec3 rolled = vec3(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a), p.z);
    return rolled;
}

// This function pitches a point by an angle a around the origin
vec3 pitch(vec3 p, float a)
{
    vec3 pitched = vec3(p.x, p.y * cos(a) - p.z * sin(a), p.y * sin(a) + p.z * cos(a));
    return pitched;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.y) * 2.;
    uv -= resolution.xy/resolution.y;

    uv *= 0.12;
    
    float offsetx = (mouse.x*resolution.xy.x / (resolution.x)) * 8. + time * 0.8;
    float offsety = (mouse.y*resolution.xy.y / (resolution.y)) * 8. + time * 0.5;

    
    // Rotating and translating the vertices and storing them in the vertexbiffer
    for (int i = 0; i < VERTEXCOUNT; i++)
    {
        vertexbuffer[i] = roll(pitch(vertices[i], time * 0. + offsety), time * 0. - offsetx) - vec3(0., 0., 16.);
    }
    
    // Projecting the triangles on the  
    float col = 0.;
    for (int i = 0; i < TRIANGLECOUNT * 3; i += 3)
    {
        Tri3D tri = Tri3D(vertexbuffer[triangles[i]], vertexbuffer[triangles[i+1]],  vertexbuffer[triangles[i+2]]);
        col += mask(project(tri), uv) * light(tri);
    }
    
    glFragColor = vec4(vec3(col),1.0);
}
