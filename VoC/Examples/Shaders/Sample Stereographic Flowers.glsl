#version 420

// original https://www.shadertoy.com/view/NsSfRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define square_size 0.5f
#define cx square_size
#define cy square_size

#define speed 1.0f
#define s 1.0f
#define rotcolor(a) vec3(sin(a),sin(a+3.14/4.0),sin(a-3.14/2.0))

// Draws a checkerboard pattern.
vec3 checker(vec2 p){
    /// Here for debuging purposes. Draws a "straight" lines along the surface.
    //if (0.5<p.y && p.y<0.6) {return vec3(1,0,0);}
    //if (0.5<p.x && p.x<0.6) {return vec3(0,1,0);}
    /// Also for debuging. Draws a single square.
    //if (p.x<1.0 && 0.5<p.x && p.y<1.0 && 0.5<p.y) {return vec3(0,0,1);} 
    
    
    if (mod(floor(p.x/cx)+mod(p.y/cy,2.0),2.0)<1.0) {return vec3(rotcolor(mod(p.x,3.0)));}
    else {return vec3(0.3,0.36,0.57)*vec3(rotcolor(mod(2.0*p.y,3.0)));}
}

vec3 sphere(vec2 uv){
    vec3 sphereCoord = vec3(sin(uv.y)*cos(uv.x),sin(uv.y)*sin(uv.x),cos(uv.y));
    return sphereCoord;
}

vec3 rotate(vec3 p, float angle){
    float a = p.x;
    float b = p.y*cos(angle)-p.z*sin(angle);
    float c = p.y*sin(angle)+p.z*cos(angle);
    return vec3(a,b,c);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.y)+vec2(-0.5);
    
    //float angle = sin(time*0.01);
    //uv = uv+sin(time*(0.0,0.1));//mat2(cos(angle),-sin(angle),sin(angle),cos(angle))*uv;
    uv.x *= 3.0*3.14;
    uv.y *= 3.0*3.14;
    vec3 sphereCoord = sphere(uv);
    

    sphereCoord = rotate(sphereCoord,(3.14/2.0)).xyz;
    //Uncomment the line below for a 'slightly' more interesting effect.
    //sphereCoord = rotate(sphereCoord,(3.14/2.0)-0.5*uv.x).xyz;
    sphereCoord = rotate(sphereCoord.zxy,(speed*time)).yzx;
    
    
    float osc = 0.0;//(1.0-sin(speed*time)*sin(speed*time));
    //vec2 new = osc*uv+(1.0-osc)+vec2(sphereCoord.x/(s-sphereCoord.z),sphereCoord.y/(s-sphereCoord.z));
    
    // Convert the 3d coordinates to 2d x & y.
    vec2 new_coord = vec2(sphereCoord.x/(s-sphereCoord.z),sphereCoord.y/(s-sphereCoord.z));
    //vec3 col = rotcolor(new_coord.x)*rotcolor(new_coord.x)*checker(new_coord.xy);
    vec3 col = checker(new_coord);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
