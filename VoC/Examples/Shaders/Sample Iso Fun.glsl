#version 420

// original https://www.shadertoy.com/view/3lKBW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define PI acos(-1.)

void mo(inout vec2 p, vec2 d)
{
    p =abs(p)-d;
    if(p.y>p.x) p = p.yx;
}

float signed_box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0.,max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

float SDF (vec3 position)
{
    position.yz *=rot(time/2.*-atan(1./sqrt(2.)));
    position.xz *=rot(PI/4.*time/2.);
    
    //mo(position.xz,vec2(1.));
    mo(position.xz,vec2(abs(sin(time/2.)),abs(cos(time/2.))));
    mo(position.yz,vec2(abs(cos(time/2.)),abs(sin(time/2.))));
    position.x -= sin(time/2.)+1.;
    position.y -= cos(time/2.)+1.;
    //position.xz *= rot(time);
    //position.yz *= rot(time);
    return signed_box(position, vec3(.5));
}

vec3 get_normals (vec3 p)
{
    vec2 eps = vec2(0.001,0.);
    return normalize( SDF(p) - vec3(SDF(p-eps.xyy), SDF(p-eps.yxy),SDF(p-eps.yyx)) );
   //return vec3(0.);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
     // thanks remy ! random qui va noise les uvs, rendant un effet sur le rendu
    float rand = 0.;fract(sin(length(uv)*64.125 + fract(time*.001))*752.3216) * sin(time/3.)/100.;
    
    
    // perspective camera
    /*vec3 ray_origin = vec3(0.,0.,-2.),
    ray_direction = normalize( vec3(uv,1.) ),
    pos = ray_origin,
    */
    
    
    //orthographic camera
    vec3 ray_origin = vec3(uv*2.,-20.),
    ray_direction = normalize( vec3(vec2(0.+rand, 0.+rand),1.) ),
    pos = ray_origin,
    
    //light 
    dir_light = normalize( vec3(-1.,1.,-2.) ),
    //background color
    col = vec3(0.);
    
    bool hit = false;
    float shading;
    for (float i=0.; i<64.; i++)
    {
        float dist = SDF(pos);
        if(dist < 0.001)
        {
            hit = true;
            shading = i/64.;
            break;
        }
        pos += dist * ray_direction;
    }
    
    if (hit)
    {
        vec3 normal = get_normals(pos);
        float lighting = max(dot(normal,dir_light),0.);
        col = normal*vec3(lighting);
    }
    
    

    // Output to screen
    glFragColor = vec4(pow(col,vec3(2.)),1.0);
}
