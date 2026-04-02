#version 420

// original https://www.shadertoy.com/view/tsf3WB

#extension GL_EXT_gpu_shader4 : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License. 
/// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/.

/// color-blind safe and perceptually uniform color scale
/// adapted from:
/// https://github.com/marcosci/cividis
const vec3[] cividis = vec3[]
(
    vec3(0.0000, 0.1262, 0.3015),

    vec3(0.0000, 0.1408, 0.3334),

    vec3(0.0000, 0.1546, 0.3676),

    vec3(0.0000, 0.1685, 0.4031),

    vec3(0.0000, 0.1817, 0.4347),

    vec3(0.0000, 0.1930, 0.4361),

    vec3(0.0000, 0.2073, 0.4329),

    vec3(0.0710, 0.2215, 0.4293),

    vec3(0.1204, 0.2357, 0.4262),

    vec3(0.1566, 0.2498, 0.4236),

    vec3(0.1868, 0.2639, 0.4217),

    vec3(0.2133, 0.2780, 0.4205),

    vec3(0.2375, 0.2920, 0.4200),

    vec3(0.2599, 0.3060, 0.4202),

    vec3(0.2811, 0.3200, 0.4210),

    vec3(0.3014, 0.3340, 0.4224),

    vec3(0.3209, 0.3481, 0.4244),

    vec3(0.3398, 0.3622, 0.4270),

    vec3(0.3582, 0.3763, 0.4302),

    vec3(0.3763, 0.3904, 0.4338),

    vec3(0.3940, 0.4047, 0.4381),

    vec3(0.4114, 0.4189, 0.4430),

    vec3(0.4286, 0.4333, 0.4485),

    vec3(0.4456, 0.4477, 0.4547),

    vec3(0.4622, 0.4622, 0.4620),

    vec3(0.4790, 0.4767, 0.4691),

    vec3(0.4971, 0.4915, 0.4723),

    vec3(0.5158, 0.5065, 0.4736),

    vec3(0.5349, 0.5216, 0.4738),

    vec3(0.5541, 0.5368, 0.4733),

    vec3(0.5735, 0.5522, 0.4720),

    vec3(0.5931, 0.5678, 0.4701),

    vec3(0.6129, 0.5835, 0.4673),

    vec3(0.6328, 0.5993, 0.4641),

    vec3(0.6529, 0.6153, 0.4600),

    vec3(0.6732, 0.6315, 0.4553),

    vec3(0.6936, 0.6478, 0.4499),

    vec3(0.7142, 0.6643, 0.4437),

    vec3(0.7350, 0.6810, 0.4368),

    vec3(0.7560, 0.6979, 0.4290),

    vec3(0.7771, 0.7150, 0.4205),

    vec3(0.7985, 0.7322, 0.4111),

    vec3(0.8200, 0.7497, 0.4007),

    vec3(0.8417, 0.7674, 0.3892),

    vec3(0.8636, 0.7853, 0.3766),

    vec3(0.8858, 0.8035, 0.3627),

    vec3(0.9082, 0.8219, 0.3474),

    vec3(0.9308, 0.8405, 0.3306),

    vec3(0.9536, 0.8593, 0.3116),

    vec3(0.9767, 0.8785, 0.2901),

    vec3(1.0000, 0.8979, 0.2655),

    vec3(1.0000, 0.9169, 0.2731)
);
/// Inigo Quilez's analytic box normal  
/// adapted from:
/// http://iquilezles.org/www/articles/boxfunctions/boxfunctions.htm
vec3 boxNormal( vec3 direction, vec3 point, float radius )
{
    vec3 n = point / direction;
    vec3 s = sign(direction);
    vec3 k = s * radius / direction;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    vec3 normal = -s * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    
    return normal;
}
/// math to convert from cartesian coordinates to hexagonal coordinates
/// adapted from: 
/// https://www.redblobgames.com/grids/hexagons
vec2 cube_to_axial(vec3 cube)
{
    return cube.xz;
}
vec3 axial_to_cube(vec2 hex)
{
    float x = hex.x;
    float z = hex.y;
    float y = -x - z;
    return vec3(x, y, z);
}
vec3 cube_round(vec3 cube)
{
    float rx = round(cube.x);
    float ry = round(cube.y);
    float rz = round(cube.z);

    float x_diff = abs(rx - cube.x);
    float y_diff = abs(ry - cube.y);
    float z_diff = abs(rz - cube.z);

    bool isA = x_diff > y_diff && x_diff > z_diff;
    float fIsA = float(isA);
    rx = fIsA * (-ry-rz) + (1.0 - fIsA) * rx;
    
    bool isB = !isA && y_diff > z_diff;
    float fIsB = float(isB);
    ry = fIsB * (-rx-rz) + (1.0 - fIsB) * ry;
    
    float isC = float(!isA && !isB);
    rz = isC * (-rx-ry) + (1.0 - isC) * rz;

    return vec3(rx, ry, rz);
}
vec2 hex_round(vec2 hex)
{
    return cube_to_axial(cube_round(axial_to_cube(hex)));
}
const float sqrt3 = sqrt(3.0);
vec2 pixel_to_pointy_hex(vec2 point, float size)
{
    vec2 hex;
    const float thirdSqrt3 = sqrt3 / 3.0;
    const float third = 1.0 / 3.0;
    const float twoThirds = 2.0 / 3.0;
    hex.x = (thirdSqrt3 * point.x -     third * point.y) / size;
    hex.y = (                        twoThirds * point.y) / size;
    return hex_round(hex);
}
vec2 pointy_hex_to_pixel(vec2 hex, float size)
{
    const float halfSqrt3 = 0.5 * sqrt3;
    vec2 pixel;
    pixel.x = size * (sqrt3 * hex.x  +  halfSqrt3 * hex.y);
    pixel.y = size * (                        1.5 * hex.y);
    return pixel;
} 
/// Perlin noise
/// adapted from: 
/// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
#define M_PI 3.14159265358979323846
float rand(vec2 co){return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);}
float rand (vec2 co, float l) {return rand(vec2(rand(co), l));}
float rand (vec2 co, float l, float t) {return rand(vec2(rand(co, l), t));}
float perlin(vec2 p, float dim, float time) {
    vec2 pos = floor(p * dim);
    vec2 posx = pos + vec2(1.0, 0.0);
    vec2 posy = pos + vec2(0.0, 1.0);
    vec2 posxy = pos + vec2(1.0);
    
    float c = rand(pos, dim, time);
    float cx = rand(posx, dim, time);
    float cy = rand(posy, dim, time);
    float cxy = rand(posxy, dim, time);
    
    vec2 d = fract(p * dim);
    d = -0.5 * cos(d * M_PI) + 0.5;
    
    float ccx = mix(c, cx, d.x);
    float cycxy = mix(cy, cxy, d.x);
    float center = mix(ccx, cycxy, d.y);
    
    return center * 2.0 - 1.0;
}

// vector form of a line
struct Line
{
    // unit vector in the direction of the line
    vec3 direction;
    // position of a point on the line
    vec3 point;
};
// geometry of a shape used for rendering
struct Shape
{
    // distance to outline of shape
    float dist;
    // surface normal of shape
    vec3 normal;
};
// location in the hexagonal grid
struct Hex
{
    // index of current hexagon
    vec2 index;
    // offset from center of current hexagon
    vec2 point;
};
// clone geometry in hexagonal pattern
Hex hexGrid (vec2 point, float gridSize)
{
    const float hexSize = 1.0;
    vec2 q = point * gridSize;
    Hex hex;
    hex.index = pixel_to_pointy_hex(q, hexSize);
    hex.point = q - pointy_hex_to_pixel(hex.index, hexSize);
    return hex;
}
// maximum element of absolute value of vector
// see: https://en.wikipedia.org/wiki/Uniform_norm
float supremumNorm(vec3 v)
{
    vec3 u = abs(v);
    float norm = max(max(u.x, u.y), u.z);
    return norm;
}
// calculates geometry of a cube
Shape cube(Line line, float radius)
{
    /// find distance
    float dist;
    const int size = 3;
    // search edges of cube for nearest point
    dist = 999999999.0;
    for (int m = 0; m < size; m++)
    {
        float t;
        vec3 v;
        float d;
        
        int n = (m + 1) % size;
        float x = line.point[m];
        float y = line.point[n];
        float i = line.direction[m];
        float j = line.direction[n];
        
        t = (-x + y) / (i - j);
        v = line.point + line.direction * t;
        d = supremumNorm(v);
        dist = min(dist, d);
        
        t = (-x - y) / (i + j);
        v = line.point + line.direction * t;
        d = supremumNorm(v);
        dist = min(dist, d);
    }
    dist -= radius;
    /// find normal
    // sample normals in plane around point
    vec3 horizontal = cross(line.direction, vec3(0.0, 1.0, 0.0));
    vec3 vertical = cross(horizontal, line.direction);
    // give extra weight to the normal of the current point
    float total;
    vec3 normal;
    // sample normals in octagonal pattern
    for(float i = -1.0; i <= 1.0; i++)
    {
        for(float j = -1.0; j <= 1.0; j++)
        {
            vec3 offset = 0.015625 * radius * (i * horizontal + j * vertical);
            normal += boxNormal(line.direction, line.point + offset, radius);
            
            total++;
        }
    }
    // blur normals together
    normal /= total;
    /// return shape data
    Shape shape;
    shape.dist = dist;
    shape.normal = normal;
    
    return shape;
}
// rotates a vector by a given angle (in radians) around a given axis (must be a unit vector)
// see: https://en.wikipedia.org/wiki/Rodrigues'_rotation_formula
vec3 rotationRodrigues(vec3 v, vec3 axis, float angle)
{
    float c = cos(angle);
    return v * c + cross(axis, v) * sin(angle) + axis * dot(axis, v) * (1.0 - c);
}
// diffuse lighting
vec3 lightDiffuse(vec3 normal, vec3 light)
{
    float intensity = 0.5 + 0.5 * dot(normal, light);
    // cache useful cividis values for performance
    const int cividisCount = cividis.length() - 1;
    const float cividisScale = float(cividisCount);
    // approximately cividis scale sampling
    intensity *= cividisScale;
    int index = int(round(intensity));
    vec3 color = cividis[index];
    return color;
}
// manage the light and camera for the scene
void lightsCameraAction(vec2 point, out Line viewLine, out vec3 light, float time)
{
    vec3 viewPoint, viewDirection;
    float angle;
    vec3 axis;
    // rotate 1/8th turn around the x-axis and 1/8th turn around the y-axis
    angle = 1.09606;
    axis = vec3(0.678598, 0.678598, -0.281086);
    viewPoint = vec3(point, -100.0);
    viewPoint = rotationRodrigues(viewPoint, axis, angle);
    viewDirection = vec3(0.5, -0.707108, 0.499998);
    light = vec3(-0.406773, 0.814675, 0.41333);
    // animate rotation
    angle = time;
    axis = vec3(0.57735, 0.57735, 0.57735);
    viewPoint = rotationRodrigues(viewPoint, axis, angle);
    viewDirection = rotationRodrigues(viewDirection, axis, angle);
    light = rotationRodrigues(light, axis, angle);
    // construct view line
    viewLine.point = viewPoint;
    viewLine.direction = viewDirection;
}
// draw antialiased point with minimum pixel size 
vec3 draw(in vec3 buffer, in float dist, in float radius, in vec3 color)
{
    float up = min(resolution.x, resolution.y);
    dist *= up;
    const float scale =  1.0 / 360.0;
    radius *= up * scale;
      float aa = 0.5 * fwidth(dist);
    vec3 mixed = mix(buffer, color, 1.0 - smoothstep(radius - aa, radius + aa, dist));
       return mixed;
}
// render scene
vec3 render(vec2 gl_FragCoord, Line line, vec3 light, float gridSize, float time, float zoom)
{
    // find shape
    const float radius = 1.0 / 3.0;
    Shape cube = cube(line, radius);
    float dist = cube.dist;
    vec3 normal = cube.normal;
    // no-see-um green with Perlin noise for background
    const vec3 green = vec3(139.0 / 255.0, 153.0 / 255.0, 153.0 / 255.0);
    vec3 background = green + 0.0625 * vec3(perlin(gl_FragCoord, 1.0, fract(time)));
    // add lighting
    vec3 color;
    color = lightDiffuse(normal, light);
    // check whether the pixel is on a shape or the background
    float isInside = float(dist <= 0.0);
    color = background * (1.0 - isInside) + isInside * color;
    // distance to shape edge
    float outline = abs(dist);
    // desired pixel radius of line
    float lineRadius = 1.0;
    // compensate for grid
    lineRadius *= gridSize;
    // draw shape outline
    vec3 border = mix(vec3(0.0), vec3(0.25), zoom);
    color = draw(color, outline, lineRadius, border);
    return color;
}

void main(void)
{
    // mathematical constant
    const float pi = 3.1415926535897932384626433832795;
    // normalize pixel coordinates and center on origin
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / min(resolution.x, resolution.y);
    // zoom in and out
    float zoom = smoothstep(-1.0, 1.0, cos(0.5 * time));
    float gridSize = mix(3.0, 21.0, zoom);
    // map to hexagonal grid
    Hex hex = hexGrid(uv, gridSize);
    // lock everything to running time
    const float speed = 2.0;
    float time = speed * time;
    // alternate animation timing on hex grid
    const vec2 c = vec2(1.0, 2.0);
    float vertexColor = dot(mod(hex.index, 2.0), c);
    const float shift = pi / 6.0;
    time += vertexColor * shift;
    // set up the camera and light for the scene
    Line viewLine;
    vec3 light;
    lightsCameraAction(hex.point, viewLine, light, time);
    // render objects
    vec3 color = render(gl_FragCoord.xy, viewLine, light, gridSize, time, zoom);
    // Output to screen
    glFragColor = vec4(color, 1.0);
}
