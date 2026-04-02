#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tssXzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 cmult(vec2 a, vec2 b)
{

    return mat2(a,-a.y,a.x) * b;
}

vec2 spacify(vec2 p)
{
    return ( p - .5 * resolution.xy ) / resolution.y;
}

int julia(in vec2 z0, in vec2 c)
{
    vec2 z = z0;
    if (length(z) > 4.0)
        return 0;
    for (int n=0; n <12; n++) {
        z = cmult(z,z) +c;

        if (length(z) > 4.0) return n;
    }
    return -1;
}

mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c           );
}

void main(void)
{
    // start at 0,0,z=3, shoot a ray at the plane z=1
    //vec3 camera = vec3(0.2*sin(time/2.3),0.2*cos(time/18.8),4.0);
    vec3 camera = vec3(0,0,4.0);
    vec2 xy = spacify(gl_FragCoord.xy);
    vec3 coord = vec3(xy.x, xy.y, 3.0);
    vec3 ray = coord - camera;
    
    vec2 mouse_xy=spacify(mouse*resolution.xy.xy);
    mat3 rot = rotationMatrix(vec3(mouse_xy.y, mouse_xy.x, 0.0),1.5*length(mouse_xy));
    
    camera = camera*rot;
    ray = ray*rot;
    
    vec4 col = vec4(0.0,0.0,0.0,0.0);
    float core = 0.0;
    float steps = 50.0;
    float z2 = sin(time/7.0);
    vec3 pos; int inc;
    for (float n=0.0; n<steps; n+=0.025) {
        pos = camera + n*ray;
        inc = julia( vec2(pos.z,z2),vec2(pos.x, pos.y));
        
        if (inc < 0)
            // collisions with the core of the julia set
            core += 1.0;
        else {
            // collisions with the halo
            col.x += float(inc);
            if (inc % 2 == 0) {
                col.y += float(inc);
                col.z += float(inc);
            }

        }
    }
    float scale = 10.24 * steps;//, g=4.0*scale, b=2.0*scale;
    float pen = core / 10.0;
    col /= scale;
    col.z -= pen;
    col.x = col.x * 1.0 - pen/5.0;
    col.z = col.z * 2.0 - pen;
    glFragColor = col;//vec4(col/scale - pen, abs(sin(col/scale))-(pen/5.0), col/b, 0.0);

}
