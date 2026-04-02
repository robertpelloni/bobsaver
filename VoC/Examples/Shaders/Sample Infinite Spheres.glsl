#version 420

// original https://www.shadertoy.com/view/MlKBzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int max_iters = 500;
float max_dist = 100.0;
vec3 bg_col = vec3(0.5, 0.5, 0.5);

/**
 * Rotation matrix around the Y axis.
 */
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

//the signed distance field function
//used in the ray march loop
float sdf(vec3 p) {

    //a sphere of radius 1.
    return length( p ) - 1.;
}

void main(void) {

//1 : retrieve the fragment's coordinates
    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    //preserve aspect ratio
    uv.x *= resolution.x / resolution.y;

//2 : camera position and ray direction
    vec3 pos = vec3( 2.0, 2.0,-20.);
    vec3 dir = normalize( vec3( uv, 3.0 ) );

    pos = rotateY(time / 4.0) * pos;
    dir = rotateY(time / 8.0) * dir;
    
//3 : ray march loop
    //ip will store where the ray hits the surface
    vec3 ip;

    //variable step size
    float t = 0.0;
    int i = 0;
    for(; i < max_iters; i++) {

        //update position along path
        ip = pos + dir * t;

        //gets the shortest distance to the scene
        float m = 4.0;
        ip = abs(mod(ip - m*0.5, m) - m*0.5);
        float temp = sdf( ip );

        //break the loop if the distance was too small
        //this means that we are close enough to the surface
        if( temp < 0.01 ) {
            float a = float(i) / float(max_iters);
            float diffuse = dot(ip, vec3(0.6, 0.8, 0.0))*0.5 + 0.5;
            ip = vec3(1.0, 1.0, 1.0) * diffuse * (1.0 - a) + bg_col * a;
            break;
        }
         
        //break if too far
        if (temp > max_dist) {
            ip = bg_col;
            break;
        }

        //increment the step along the ray path
        t += temp;

    }
    
    if (i == max_iters) ip = bg_col;
        

//4 : apply color to this fragment
    glFragColor = vec4( ip, 1.0);

}
