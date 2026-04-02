#version 420

// original https://www.shadertoy.com/view/tlfSWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'Rubber vector' is an old-school demo effect, which was produced by
// keeping a tail of frames and displaying older frames the further down
// on the screen.
//
// While experimenting with implementing triangle rasterization in ShaderToy,
// I thought about this, and implemented it by adjusting time using the
// Y-component of the screen space position.

mat4 rotationMatrix(vec3 axis, float angle)
{
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;
    float c = cos(angle);
    float s = sin(angle);
    return mat4(
        x*x*(1.0-c) +   c, y*x*(1.0-c) + z*s, x*z*(1.0-c) - y*s, 0,
        x*y*(1.0-c) - z*s, y*y*(1.0-c) +   c, y*z*(1.0-c) + x*s, 0,
        y*z*(1.0-c) + y*s, y*z*(1.0-c) - x*s, z*z*(1.0-c) +   c, 0,
        0,                                 0,                 0, 1
    );
}

mat4 translationMatrix(vec3 o)
{
    return mat4(
        1, 0, 0, 0,
        0, 1, 0, 0, 
        0, 0, 1, 0,
        o.x, o.y, o.z, 1
    );
}
    

mat4 frustumMatrix(float l, float r, float b, float t, float n, float f)
{
    return mat4(
        2.0*n/(r-l), 0, 0, 0,
        0, 2.0*n/(t-b), 0, 0,
        (r+l)/(r-l), (t+b)/(t-b), -(f+n)/(f-n), -1,
        0, 0, -2.0*f*n/(f-n), 0
    );
}

float cross2(vec2 a, vec2 b)
{
    return cross(vec3(a, 0), vec3(b, 0)).z;   
}

void rasterizeTriangle(inout float depth,
                       inout vec3 normal,
                       in vec4 a, in vec4 b, in vec4 c,
                       in vec2 p,
                       in vec3 n)
{
    vec2 ab = b.xy - a.xy;
    vec2 bc = c.xy - b.xy;
    vec2 ca = a.xy - c.xy;
    
    vec2 ap = p - a.xy;
    vec2 bp = p - b.xy;
    vec2 cp = p - c.xy;
    
    // Back-face culling
    float area_abc = cross2(ab, bc);
    if(area_abc <= 0.0) return;

    // Point-in-triangle test
    float area_abp = cross2(ab, bp);
    float area_bcp = cross2(bc, cp);
    float area_cap = cross2(ca, ap);
    if(area_abc <= 0.0 || area_abp < 0.0 || area_bcp < 0.0 || area_cap < 0.0) return;
    
    // shape is convex and backface culled, so we don't need depth beyond flagging
    // that it is not background.
    depth = 0.0;
    normal = n;
}

vec4 perspectiveDivide(vec4 h)
{
    return (1.0/h.w)*vec4(h.xyz, 1);
}

void main(void)
{
    vec2 uv = 2.0*gl_FragCoord.xy/resolution.xy - vec2(1);

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    float t = time + sin(time)*uv.y;
    
    mat4 M =
        rotationMatrix(vec3(0,0,1), 0.3*t) *
        rotationMatrix(vec3(0,1,0), 0.7*t) *
        rotationMatrix(vec3(0,0,1), 1.1*t);

    float aspect = resolution.x/resolution.y;
    mat4 P =
        frustumMatrix(-0.2*aspect, 0.2*aspect,
                      -0.2,  0.2,
                       0.2, 30.0) *
        translationMatrix(vec3(0,0,-2.5));
        
    
    mat4 PM = P * M;
    
    vec4 c000 = perspectiveDivide(PM*vec4(-1,-1, -1, 1));
    vec4 c100 = perspectiveDivide(PM*vec4( 1,-1, -1, 1));
    vec4 c010 = perspectiveDivide(PM*vec4(-1, 1, -1, 1));
    vec4 c110 = perspectiveDivide(PM*vec4( 1, 1, -1, 1));
    vec4 c001 = perspectiveDivide(PM*vec4(-1,-1,  1, 1));
    vec4 c101 = perspectiveDivide(PM*vec4( 1,-1,  1, 1));
    vec4 c011 = perspectiveDivide(PM*vec4(-1, 1,  1, 1));
    vec4 c111 = perspectiveDivide(PM*vec4( 1, 1,  1, 1));

    vec3 n_x = mat3(M)*vec3(1,0,0);
    vec3 n_y = mat3(M)*vec3(0,1,0);
    vec3 n_z = mat3(M)*vec3(0,0,1);
    
    vec3 normal = vec3(0,0,0);
    float depth = 200.0;
    
    rasterizeTriangle(depth, normal, c100, c000, c110, uv, -n_z);
    rasterizeTriangle(depth, normal, c110, c000, c010, uv, -n_z);
    rasterizeTriangle(depth, normal, c001, c101, c111, uv, n_z);
    rasterizeTriangle(depth, normal, c001, c111, c011, uv, n_z);
        
    rasterizeTriangle(depth, normal, c000, c100, c001, uv, -n_y);
    rasterizeTriangle(depth, normal, c100, c101, c001, uv, -n_y);
    rasterizeTriangle(depth, normal, c110, c010, c011, uv, n_y);
    rasterizeTriangle(depth, normal, c111, c110, c011, uv, n_y);

    rasterizeTriangle(depth, normal, c010, c000, c011, uv, -n_x);
    rasterizeTriangle(depth, normal, c011, c000, c001, uv, -n_x);
    rasterizeTriangle(depth, normal, c100, c110, c111, uv, n_x);
    rasterizeTriangle(depth, normal, c100, c111, c101, uv, n_x);

        
    
    // Output to screen
    glFragColor = vec4(depth == 0.0 ? normal : vec3(0),1.0);
}
