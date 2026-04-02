#version 420

// original https://www.shadertoy.com/view/3lsyzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// position of the green/yellow light
vec3 gpos;

float dot2(in vec3 v) { return dot(v, v); }

float sdf_sph(in vec3 p, in float r) {
  return length(p) - r;
}

// the main blob made from two sphere
float sdf_min(in vec3 p) {
    float a = sdf_sph(p - vec3(-0.3, 0.0, 0.0), 0.3);
    float b = sdf_sph(p - vec3(0.2, 0.0, -0.2), 0.5);
    float res = exp2( -32.*a ) + exp2( -32.*b );
    return -log2( res ) / 32.;
}

// added a new sphere at the position of the purple light
float sdf_uni(in vec3 p) {
    return min(sdf_min(p), sdf_sph(p - gpos, 0.05));
}

float sdf(in vec3 p) {
    return sdf_uni(p);
}

// normal vector, gradient of sdf at p
vec3 d_sdf(in vec3 p) {
    return vec3(
               (sdf(p) - sdf(p - vec3(0.0001, 0., 0.))) / 0.0001, 
               (sdf(p) - sdf(p - vec3(0., 0.0001, 0.))) / 0.0001,
               (sdf(p) - sdf(p - vec3(0., 0., 0.0001))) / 0.0001
           );
}

void main(void)
{
    // Coordinates to y in (-1, 1), origo in (0, 0), aspect is correct
    vec2 uv = gl_FragCoord.xy / resolution.y * 2.0 - vec2(resolution.x / resolution.y, 1);
   
    
    // moving light point
    gpos = vec3(-0.2, sin(time*1.414), 0.6);
    // rotation around the y axis
    mat3 rot = mat3(cos(time), 0., -sin(time), 
                            0., 1.,          0., 
                    sin(time), 0., cos(time));
       vec3 p = rot * vec3(uv, 1.);
    vec3 dir = rot * vec3(0., 0., -1.);
    
    for(int i = 0; i < 16; ++i) {
        p = p + dir * sdf(p) * 1.0;// * sign(dot(d_sdf(p), -dir));
    }
    
    /* // Debug position
    if(abs(sdf(p)) < 2.0) {
           glFragColor = vec4(p * 0.5 + 0.5, 1.);
        return;
    } else {
        glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    //*/
    
    
    /* // Debug final sdf value
    if(sdf(p) > 0.1) {
        glFragColor = vec4(1.0);
        return;
    } else {
        glFragColor = vec4(sdf(p) * 10., -sdf(p) * 10., 0., 0.);
        return;
    } //*/
    
   
    // normal vector
    vec3 n = normalize(d_sdf(p));
    
    // blue color, from a fix direction
    vec3 bdir = normalize(vec3(-0.3, 0.4, -0.3));
       float bcol = dot(n, bdir);
    
    
    // green color, from a moving direction
    vec3 gdir = normalize(gpos - p);
    float gcol = dot(n, normalize(gdir));
    
    // red color, from a moving point, with distance
    vec3 rdir = normalize(gpos - p);
       float rcol = pow(max(dot(n, rdir), 0.), 4.);
    
    
    
    if(sdf(p) > 0.1) { 
        glFragColor = vec4(0.2, 0.2, 0.2, 1.0);
    }
    else {
        glFragColor = vec4(rcol, gcol, bcol, 1.0);
    }
}
